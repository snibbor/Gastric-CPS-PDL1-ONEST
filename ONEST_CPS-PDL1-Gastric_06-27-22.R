# library(raters)
library(irr)
# library(ONEST)
library(combinat)
library(openxlsx)
# data('sp142_bin')
# dataSP = sp142_bin
library(ggplot2)
library(reshape2)
# library(data.table)


#######################################################################################
#######################################################################################
#Backend functions for ONEST technique
#######################################################################################
#######################################################################################

#Get functions. Change directories to where the R files are located.
source('D:/Documents/Rimm/CPS-Gastric_discordance/ONEST_core.R')
source('D:/Documents/Rimm/CPS-Gastric_discordance/agree_utils.R')

#######################################################################################
#######################################################################################
#Making ONEST plots from pathologist data
#######################################################################################
#######################################################################################

#Load data
setwd('D:/Documents/Rimm/CPS-Gastric_discordance')
score_sheet = which(grepl('\\CPS Score <>1\\b', getSheetNames("Hub-ALL_Gastric_CPS.ScoreComparison-02-02-22.xlsx")))
ptiles_sheet = which(grepl('\\CPS Ventiles\\b', getSheetNames("Hub-ALL_Gastric_CPS.ScoreComparison-02-02-22.xlsx")))
data_score = read.xlsx(xlsxFile = "Hub-ALL_Gastric_CPS.ScoreComparison-02-02-22.xlsx", sheet=score_sheet, fillMergedCells = TRUE, colNames = TRUE)
data_ptiles =  read.xlsx(xlsxFile = "Hub-ALL_Gastric_CPS.ScoreComparison-02-02-22.xlsx", sheet=ptiles_sheet, fillMergedCells = TRUE, colNames = TRUE)

#Replace categories with NA
data_score[data_score=='NA NO H&E'] = NA
data_score[data_score=='indeterminate'] = NA

data_ptiles[data_ptiles=='NA NO H&E'] = NA
data_ptiles[data_ptiles=='indeterminate'] = NA
data_ptiles[data_ptiles=='<1'] = 0

#Remove all NA columns
data_score = data_score[,colSums(is.na(data_score))<nrow(data_score)]
data_ptiles = data_ptiles[,colSums(is.na(data_ptiles))<nrow(data_ptiles)]

#Remove rows that contain more than 50% NA columns
data_score = data_score[rowSums(is.na(data_score))<as.integer(ncol(data_score)*0.5),]
data_ptiles = data_ptiles[rowSums(is.na(data_ptiles))<as.integer(ncol(data_ptiles)*0.5),]

#Make rownames the case names
rownames(data_score) = data_score$`Case#`
data_score$`Case#` = NULL

rownames(data_ptiles) = data_ptiles$`Case#`
data_ptiles$`Case#` = NULL

#Clean up categories
#CPS <1 or >=1
data_score[data_score == 0] = '<1'
data_score[data_score >= 1] = '>=1'
data_score[data_score == '>1'] = '>=1'

#Percentiles
data_ptiles[data_ptiles=='10 or 5'] = 10
#Replace NAs with data_score values
data_ptiles[is.na(data_ptiles)] = data_score[is.na(data_ptiles)]
data_ptiles[data_ptiles=='<1'] = 0
data_ptiles[data_ptiles=='>=1'] = 1

#Include or exclude HW
# data_score = data_score[,!(names(data_score) %in% 'HW')]
# data_ptiles = data_ptiles[,!(names(data_ptiles) %in% 'HW')]

#######################################################################################
#######################################################################################
#Generate ONEST data for CPS score groupings
#######################################################################################
#######################################################################################

dir.create(file.path(getwd(),'ONEST_concord'))

#ONEST plots for 2 category CPS score (<1, >=1)
results = ONEST_plot(data_score, plotI=T, metric = 'OPA', perAgree=100)
write.table(results$concord, 'ONEST_concord/CPS-gastric_concordance-opa.txt', sep='\t', row.names = F, quote = F)
write.table(results$stats, 'ONEST_concord/CPS-gastric_plotStats-opa.txt', sep='\t', row.names = F, quote = F)

consist = data.frame(results$modelData$consistency)
consist$path_number = 2:(nrow(consist)+1)
diff = data.frame(results$modelData$difference)
diff$path_number = 2:(nrow(consist))
mData = merge(consist, diff, by = 'path_number', all = TRUE)
write.table(mData, paste0('ONEST_concord/','CPS-gastric_modelData-opa.txt'), sep='\t', row.names = F, quote = F)


#ICC ONEST plot for percentile CPS score
results = ONEST_plot(data_ptiles, plotI=T, metric = 'icc')
write.table(results$concord, 'ONEST_concord/perCPS-gastric_concordance-icc.txt', sep='\t', row.names = F, quote = F)
write.table(results$stats, 'ONEST_concord/perCPS-gastric_plotStats-icc.txt', sep='\t', row.names = F, quote = F)

#Histogram of percentile scores, to view where the relative cutpoints are
# new_data=na.omit(as.vector(data.matrix(data_ptiles)))
# hist(new_data)
# d = density(new_data)
# plot(d)

# #Group by x<1, 1=< x <5, 5=< x 10,... every 5, every 10, every 20
# cats = c('<1', '>=1', 'every20')
# data_ptiles = data.frame(lapply(data_ptiles, as.numeric))
# 
# #Need to make data_backup. Changing the data from numeric to characters while evaluating
# #inequalities messes up the indexing for dataframe
# 
# data_backup = data_ptiles
# for(i in 1:length(cats)){
#   if(grepl('every',cats[i])){
#     every = as.integer(gsub('every','',cats[i]))
#     iter = as.integer(100/every)
#     start = 1
#     for(j in 0:iter){
#       if(j==0){
#         ineq = paste0('data_backup>',start,' & data_backup<=',every*(j+1))
#         group_label = paste0(start,'< x <=',every*(j+1))
#       } else { 
#         ineq = paste0('data_backup>',every*j,' & data_backup<=',every*(j+1))
#         group_label = paste0(every*j,'< x <=',every*(j+1))
#       }
#       
#       data_ptiles[eval(parse(text=ineq))] = group_label
#     }
#   } else {
#     ineq = paste0('data_backup',cats[i])
#     data_ptiles[eval(parse(text=ineq))] = cats[i]
#   }
#   
# }
# 
# results = ONEST_plot(data_ptiles, plotI=T, metric = 'OPA')
# write.table(results$concord, 'ONEST_concord/20perCPS-gastric_concordance-opa.txt', sep='\t', row.names = F, quote = F)
# write.table(results$stats, 'ONEST_concord/20perCPS-gastric_plotStats-opa.txt', sep='\t', row.names = F, quote = F)
# data_ptiles = data_backup

makeCats <- function(data, cats, group_label=F, make_ordinal=F){
  row_names = rownames(data)
  data_backup = data.frame(lapply(data, as.numeric))
  rownames(data_backup)= row_names
  # data_backup = data.frame(data)
  data_cats = data_backup
  for(i in 1:length(cats)){
    if(grepl('-',cats[i])){
      bounds = strsplit(cats[i],'-')
      b_low = bounds[[1]][1]
      b_high = bounds[[1]][2]
      ineq = paste0('data_backup',b_low,' & data_backup',b_high)
      if(group_label==T){
        data_cats[eval(parse(text=ineq))] = cats[i]
      } else{
        data_cats[eval(parse(text=ineq))] = i-1
      }
    } else {
      ineq = paste0('data_backup',cats[i])
      # cat(ineq)
      if(group_label==T){
        data_cats[eval(parse(text=ineq))] = cats[i]
      } else{
        data_cats[eval(parse(text=ineq))] = i-1
      }
    }
  }
  if(make_ordinal==T && group_label==F){
    data_cats = data.frame(lapply(data_cats, function(x) ordered(x, levels=0:(length(cats)-1))))
    rownames(data_cats) = row_names
  }
  return(data_cats)
}

#Run one of these lines to categorize the percentile data
#LGper
#<1, 1-10, 10-20, 20-50, and 50-100
cats = c('>=0-<1', '>=1-<=10', '>10-<=20', '>20-<=50', '>50-<=100')
#<10, >10
cats = c('<10', '>=10')
#<20, >20
cats = c('<20', '>=20')
#SMper
#<1,1-20, >20
cats = c('<1', '>=1-<=20', '>20')

data_cats = makeCats(data_ptiles, cats, group_label=T, make_ordinal = F)

results = ONEST_plot(data_cats, plotI=T, metric = 'OPA', perAgree = 100)
#Change file name depending on cats category
write.table(results$concord, 'ONEST_concord/SMperCPS-gastric_concordance-opa.txt', sep='\t', row.names = F, quote = F)
write.table(results$stats, 'ONEST_concord/SMperCPS-gastric_plotStats-opa.txt', sep='\t', row.names = F, quote = F)



#Can only run this if there are only 2 categories
consist = data.frame(results$modelData$consistency)
consist$path_number = 2:(nrow(consist)+1)
diff = data.frame(results$modelData$difference)
diff$path_number = 2:(nrow(consist))
mData = merge(consist, diff, by = 'path_number', all = TRUE)
write.table(mData, paste0('ONEST_concord/','LGperCPS-gastric_modelData-opa.txt'), sep='\t', row.names = F, quote = F)


#######################################################################################
#######################################################################################
#Plotting CPS ONEST plots
#######################################################################################
#######################################################################################

desiredPlots = c('CPS-gastric',
                 'LGperCPS-gastric',
                 'SMperCPS-gastric',
                 'lt10perCPS-gastric',
                 'lt20perCPS-gastric'
                 )
labels = c('CPS score (<1, >=1)', 
           'CPS score (<1, 1-10, 10-20, 20-50, and 50-100)',
           'CPS score (<1, 1-20, >20)',
           'CPS score (<10, >=10)',
           'CPS score (<20, >=20)'
           )

desiredPlots = c('perCPS-gastric')
labels = c('Percent CPS score')

# datadir = 'ONEST_concord/ICC'
# datadir = 'ONEST_concord/Fleiss_Kappa'
# datadir = 'ONEST_concord/OPA_excludeHW/90perAgree'
datadir = 'ONEST_concord/OPA'


flist = list.files(datadir)

for (i in 1:length(desiredPlots)){
  #Find files with similar matching names
  print(paste0('Working on ', desiredPlots[i],' plots...'))
  loadFiles = flist[grep(paste0("^",desiredPlots[i]), flist)]
  concord = read.delim(paste0(datadir,'/',loadFiles[grep('concord',loadFiles)]), sep='\t')
  plot_data = read.delim(paste0(datadir,'/',loadFiles[grep('plotStats',loadFiles)]), sep='\t')
  # ONEST_plot_fromData(concord, plot_data, name=labels[i], file=desiredPlots[i], ylab="ICC", color='blue', percent = F)
  # ONEST_plot_fromData(concord, plot_data, name=labels[i], file=desiredPlots[i], ylab="Fleiss' Kappa", color='red', percent = F)
  ONEST_plot_fromData(concord, plot_data, name=labels[i], file=desiredPlots[i], ylab="Overall Percent Agreement", color='black', percent = T, dpi=2000)
  if(length(loadFiles)==3){
    model_data = read.delim(paste0(datadir,'/',loadFiles[grep('modelData',loadFiles)]), sep='\t')
    ONEST_plotModel_fromData(model_data, name=labels[i], file=desiredPlots[i], percent=TRUE, dpi=2000)
  }
}

#######################################################################################
#######################################################################################
#Plotting CPS gastric stacked bar graphs
#######################################################################################
#######################################################################################

staRes = perCaseBar(data_score, name='',file='CPS-gastric', legendTitle = 'CPS score', C=100)
staResPath = perPathBar(data_score, name='Percent of gastric CPS score assigned by each pathologist',file='CPS-gastric', legendTitle = 'CPS score')


#######################################################################################
#######################################################################################
#Creating table of inter-rater reliability metrics for gastric IHC CPS
#######################################################################################
#######################################################################################

group = c('gt1', 'gt10','gt20',
          '(1,1-20,20)',
          '(1,1-10,10-20,20-50,50)')

cat_list = list(c('<1','>=1'),
                c('<10', '>=10'),
                c('<20', '>=20'),
                c('<1', '>=1-<=20', '>20'),
                c('>=0-<1', '>=1-<=10', '>10-<=20', '>20-<=50', '>50-<=100'))

data_ptiles = data.frame(lapply(data_ptiles, as.numeric))

metTab = data.frame(group)
metTab$OPA = NA
metTab$Fkappa = NA
metTab$ICC = NA
rownames(metTab) = metTab$group
library(raters)

for(i in 1:length(cat_list)){
  cats = unlist(cat_list[i])
  data_cats = makeCats(data_ptiles, cats, group_label=T, make_ordinal = F)
  metTab = fillTable(data_cats, metTab, group[i], noICC=F)
}

write.table(metTab, 'Gastric-CPS-PDL1-discordance-metrics_allPath.txt', sep='\t', row.names=F, quote=F)
