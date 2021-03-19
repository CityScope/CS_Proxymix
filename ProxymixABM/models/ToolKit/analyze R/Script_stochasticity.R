#Function to make a boxplot from a given column of the CSV containing aggregated data given number of replicates
make_boxplot <- function(df_aggregation,number_replicates_categories, column_values){
    #Dataframe that will contain the values of X simulation for each box given a number of replicates
    df_boxplot <- data.frame(Category=character(),Value=numeric(),stringsAsFactors = F)
    #Loading the dataframe picking randomly X replicates from the dataframe
    for(a_number_of_replicates in number_replicates_categories){
      df_boxplot <- rbind(df_boxplot,data.frame(Category=rep(a_number_of_replicates,times=a_number_of_replicates),Value=df_aggregation[sample(1:nrow(df_aggregation),a_number_of_replicates),column_values],stringsAsFactors = F))
    }
    #Plotting the boxplot
    boxplot(Value~Category,data = df_boxplot,xlab = "Number of replicates",ylab = colnames(df_aggregation)[column_values],las=1)
}
#Function to plot the standard error according given number of replicates
make_standard_error_plot <- function(df_aggregation,max_number_replicates,column_values){
  #Vector that will contain the standard error given a number of replicates
  v_standard_error <- c()
  #Loading the vector of the standard error by randomly picking X replicates from the dataframe
  for(a_number_of_replicates in 2:max_number_replicates){
    #Calculating the standard error (standard deviation / number of replicates)
    sd_error <- sd(df_aggregation[sample(1:nrow(df_aggregation),a_number_of_replicates),column_values])/a_number_of_replicates
    v_standard_error <- c(v_standard_error,sd_error)
  }
  #Plotting the standard error
  plot(v_standard_error,ylab="Standard error",xlab="Number of replicates",las=1,type="l")
}
#Function to plot the median, mean, maximum and minimum of a given number of replicates for rates
make_median_mean_max_min_plot <- function(df_data,number_replicates_categories,label){
  #Color for the mean line
  color_mean <- rgb(1,0,0)
  #Color for the median line
  color_median <- rgb(0,0,1)
  #Color for the min max lines
  color_min_max <- rgb(0,0,0)
  #Color for confidence interval area
  color_CI <- rgb(0.2,0.6,0.8)
  
  #Plot the lines for a given number of replicates
  for(a_number_of_replicates in number_replicates_categories){
    #Pick randomly X replicates
    index_picked <- sample(1:nrow(df_data),a_number_of_replicates)
    #Matrix that will contain the values to plot: DO NOT HESITATE TO REMOVE THE ONES YOU DON'T WANT AND CHANGE THE NUMBER OF ROWS
    # Here, the matrix has 6 rows (Mean, Median, Min, Max, 0.025 and 0.975 quantiles)
    mat_plot <- matrix(NA,nrow=6,ncol=ncol(df_data)-1)
    for(a_week in 2:ncol(df_data)){
      mat_plot[1,a_week-1] <- mean(df_data[index_picked,a_week])
      mat_plot[2,a_week-1] <- median(df_data[index_picked,a_week])
      mat_plot[3,a_week-1] <- min(df_data[index_picked,a_week])
      mat_plot[4,a_week-1] <- max(df_data[index_picked,a_week])
      mat_plot[5,a_week-1] <- quantile(df_data[index_picked,a_week],probs = 0.025)
      mat_plot[6,a_week-1] <- quantile(df_data[index_picked,a_week],probs = 0.975)
    }
    #Make the plot
    plot(NA,xlim=c(1,ncol(df_data)-1),ylim=c(0,max(mat_plot[6,])),xlab="t (hour)",ylab=label,las=1)
    #Draw the polygon for the CI first to not alter the colors of the lines when overlapping
    polygon(x=c(1:(ncol(df_data)-1),(ncol(df_data)-1):1),y = c(mat_plot[5,],rev(mat_plot[6,])),col=color_CI)
    lines(mat_plot[1,],col=color_mean)
    lines(mat_plot[2,],col=color_median)
    lines(mat_plot[3,],col=color_min_max)
    lines(mat_plot[4,],col=color_min_max)
    #Add the text at the top left of the chart
    mtext(paste(a_number_of_replicates,"rep"),side=3,adj=0)
    
    #Add the legend to the first graph, on the top right corner
    if(which(number_replicates_categories==a_number_of_replicates)==1){
      legend("topright",legend = c("95% CI","Mean","Median","Min/Max"), fill = c(color_CI,NA,NA,NA),
             col=c(NA,color_mean,color_median,color_min_max),lty = c(NA,1,1,1),border = c("black",NA,NA,NA),
             x.intersp = c(-0.5,1,1,1),box.col = "black")
    }
  }
}

#REPLACE IT BY THE DIRECTORY CONTAINING THE CSV FILES
folder_data <- "/Users/admin_ptaillandie/Desktop/Proximy - analyse R"
file_aggregation_data_end_simulation <- "result_stochasticity.csv"
file_step_direct <- "result_stochasticity_direct.csv"
file_step_object <- "result_stochasticity_object.csv"
file_step_air <- "result_stochasticity_air.csv"

#CHANGING THE PATH OF THE WORKSPACE
setwd(folder_data)
df_aggregation_data <- read.csv(file_aggregation_data_end_simulation,stringsAsFactors = F,sep = ",")
df_step_direct <- read.csv(file_step_direct,stringsAsFactors = F,sep = ",")
df_step_object <- read.csv(file_step_object,stringsAsFactors = F,sep = ",")
df_step_nb_air<- read.csv(file_step_air ,stringsAsFactors = F,sep = ",")

index_direct <- 2
index_object <- 3
index_air <- 4

#Maximum number of replicates from the file (Situation 2)
max_number_replicates <- 100
#Number of replicates categories studied 
number_replicates_categories <- c(10, 20, 50, 100)

#I just want one graph per plot here 
par(mfrow=c(1,1))
#Plotting the boxplot for injured
make_boxplot(df_aggregation_data,number_replicates_categories,index_object)
#Plotting the boxplot for dead
make_boxplot(df_aggregation_data,number_replicates_categories,index_direct)

make_boxplot(df_aggregation_data,number_replicates_categories,index_air)


#It's possible to merge both graphs in one plot, if you want to
par(mfrow=c(3,1))
#Plotting the standard error for injured
make_standard_error_plot(df_aggregation_data,max_number_replicates,index_object)
mtext(colnames(df_aggregation_data)[index_object],side=3,adj=0)
#Plotting the standard error for dead
make_standard_error_plot(df_aggregation_data,max_number_replicates,index_direct)
mtext(colnames(df_aggregation_data)[index_direct],side=3,adj=0)
#Plotting the standard error for car
make_standard_error_plot(df_aggregation_data,max_number_replicates,index_air)
mtext(colnames(df_aggregation_data)[index_air],side=3,adj=0)
#Plotting the standard error for building

#Plot the different graphs for replicates
par(mfrow=c(length(number_replicates_categories),1))
make_median_mean_max_min_plot(df_step_direct,number_replicates_categories,colnames(df_aggregation_data)[index_direct])
make_median_mean_max_min_plot(df_step_object,number_replicates_categories,colnames(df_aggregation_data)[index_object])
make_median_mean_max_min_plot(df_step_nb_air,number_replicates_categories,colnames(df_aggregation_data)[index_air])


