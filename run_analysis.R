# Edit this to set the working directory
workDir <- "."
setwd(workDir)

# load the required packages
require("data.table")
require("reshape2")

#get data from URL source
fileUrl <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
fileNanme <- rev(strsplit(URLdecode(fileUrl),"/")[[1]])[1]

if(!file.exists(fileNanme)){
  download.file(fileUrl,destfile=fileNanme ,method="auto")
}

dataDir <- strsplit(fileNanme,".", fixed=TRUE)[[1]][1]

# unzip-it if it's necessary
if(!file.exists(dataDir)){
  unzip(fileNanme)
}

# list the containing files
dataFiles <-  list.files(dataDir, recursive=TRUE)

# read test data

subject_test <- fread(file.path(dataDir,dataFiles[14]))
setnames(subject_test, "V1", "Subject") 

activity_test <- fread(file.path(dataDir,dataFiles[16]))
setnames(activity_test, "V1", "ActivityCode") 

#merge the subject and activity tables
Subj_Act_test <- cbind(subject_test,activity_test)

rm(list=c("subject_test", "activity_test"))

#somehow fread() fails to open the measurement data file
measData_test <-read.table(file.path(dataDir,dataFiles[15]))
measData_test <-data.table(measData_test)

# read counm names from the features file
attributes <- t(fread(file.path(dataDir,dataFiles[2]))[,V2])

# transpose and apply names
setnames(measData_test, attributes)


# merge the Subject, ActivityCode and Mesurement data
test_data <- cbind(Subj_Act_test, measData_test)

# cleanup
rm(list=c("Subj_Act_test", "measData_test"))


# read train data

subject_train <- fread(file.path(dataDir,dataFiles[26]))
setnames(subject_train, "V1", "Subject") 

activity_train <- fread(file.path(dataDir,dataFiles[28]))
setnames(activity_train, "V1", "ActivityCode") 

#merge the subject and activity tables
Subj_Act_train <- cbind(subject_train, activity_train)

rm(list=c("subject_train", "activity_train"))

#somehow fread() fails to open the measurement data file
measData_train <-read.table(file.path(dataDir,dataFiles[27]))
measData_train <-data.table(measData_train)


# transpose and apply names
setnames(measData_train, attributes)


# merge the Subject, ActivityCode and Mesurement data
train_data <- cbind(Subj_Act_train, measData_train)

# cleanup
rm(list=c("Subj_Act_train", "measData_train"))


# merge the( test and train data
DT <- rbind(train_data, test_data) 

# cleanup
rm(list=c("train_data", "test_data"))

# create a vector with all "mean()" and "std()" column names
Cols_mean_std <- c("Subject", "ActivityCode", names(DT)[grepl("^.*mean|std.*$",names(DT))])

#subset the to these colums
DT = DT[,Cols_mean_std, with=FALSE]

# cleanup
rm(Cols_mean_std)

# read the acitivity names   
ActivityNames <- fread(file.path(dataDir,dataFiles[1]))
setnames(ActivityNames, c("ActivityCode", "ActivityName"))   


# merge the mesurement table with activity table 
DT <- merge(ActivityNames, DT, by="ActivityCode", all.x=TRUE)
setkey(DT,Subject, ActivityName)

rm(list=c("ActivityNames", "attributes"))

# save the table to file
write.table(DT, "HAR_Dataset_tidy.txt", row.name=FALSE)
