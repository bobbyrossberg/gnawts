import os,time,datetime

# Purpose: Execute summary index searches on archived data via Splunk CLI.  This version
#          provides the option to use the dispatch API instead of the vanilla search command.
#          The dispatch API can be used in cases where it is simply not possible to work
#          within the max results limit.

#---------- change these variables ----------


startDate = "11/01/2010"
startTime = "00:00:00"
endDate = "02/10/2011"
endTime = "00:00:00"

intervalInMins = 1440

# default maxresults for CLI searches is 100
maxResults = 50000

# enable dispatch API when maxResults is simply too small
# set maxOut as appropriate, but the default 100 should be ok
useDispatch = True
maxOut = 100

#---------- begin script ----------

# break down the start/end date and time

startDateTokens = startDate.split("/")
startMonth = int(startDateTokens[0])
startDay = int(startDateTokens[1])
startYear = int(startDateTokens[2])

startTimeTokens = startTime.split(':')
startHour = int(startTimeTokens[0])
startMin = int(startTimeTokens[1])
startSec = int(startTimeTokens[2])

endDateTokens = endDate.split("/")
endMonth = int(endDateTokens[0])
endDay = int(endDateTokens[1])
endYear = int(endDateTokens[2])

endTimeTokens = endTime.split(':')
endHour = int(endTimeTokens[0])
endMin = int(endTimeTokens[1])
endSec = int(endTimeTokens[2])

# initialize start and end dates/times

startDate = datetime.datetime(startYear,startMonth,startDay,startHour,startMin,startSec)
endDate = datetime.datetime(startYear,startMonth,startDay,startHour,startMin,startSec)
endDate += datetime.timedelta(minutes=int(intervalInMins))
finishLineDate = datetime.datetime(endYear,endMonth,endDay,endHour,endMin,endSec)

# generate and run splunk search commands via CLI

i = 0


while (startDate < finishLineDate):

  # if near the finish line, set endDate = finishLineDate
  if (endDate >= finishLineDate):
    endDate = datetime.datetime(endYear,endMonth,endDay,endHour,endMin,endSec)

  # convert date/time format to MM/DD/YYYY:HH:mm:ss
  startTime = startDate.strftime("%m/%d/%Y:%H:%M:%S")
  endTime = endDate.strftime("%m/%d/%Y:%H:%M:%S")

  splunkSearch1 = "index=summary systemState=* | eval systemInterrupt=if(systemState==\"uptime\",1,0) | append [search systemState=* index=summary latest=" + endTime + "| head 1 | eval systemState=if(systemState==\"downtime\",\"uptime\",\"downtime\") "
  splunkSearch2 = " eval durationHours=((nowTime-_time)/3600) | eval _time=nowTime] | eval uptime=if(systemState==\"uptime\",1,0) | eval systemUptimeHoursInPeriod=uptime*min(100000,durationHours,24) | stats sum(systemUptimeHoursInPeriod) AS systemUptimeHoursToday, sum(systemInterrupt) as systemInterruptCountToday"
  searchCmd = "starttime=\"" + startTime + "\" endtime=\"" + endTime + "\" " + splunkSearch1 + " | eval nowTime=strptime(\"" + endTime + "\",\"%m/%d/%Y:%H:%M:%S\") | " + splunkSearch2 + " | collect index=summary"

  # run it!
  if (bool(useDispatch)):
    searchCLI = "splunk dispatch \'" + searchCmd + "\' -maxout " + str(maxOut)
  else:
    searchCLI = "splunk search \"" + searchCmd + "\" -maxresults " + str(maxResults)
  print "\n\nExecuting [" + searchCLI + "]"
  result = str.split(os.popen(searchCLI).read())
  print result

  # increment start and end dates by intervalInMins
  startDate += datetime.timedelta(minutes=int(intervalInMins))
  endDate += datetime.timedelta(minutes=int(intervalInMins))

  # track number of searches run
  i += 1

print "Done running " + str(i) + " searches!"
