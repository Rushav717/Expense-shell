#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%T)
LOG_FILE_NAME="$LOG_FOLDER|$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $! -ne 0 ]
    then
      echo -e "$2 ... $R FAILURE $N"
      exit1
    else
      echo -e "$2 ... $G Success $N"
}


CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
      echo "ERROR:: Sudo access is Required to execute the script"
      exit 1
    fi
}

echo "Script Started excecuted at: $TIMESTAMP" &>> $LOG_FILE_NAME

CHECK_ROOT

dnf install mysql-server -y 
VALIDATE $? "Installing Mysql server"

systemctl enable mysqld
VALIDATE $? "Enabling Mysql server"

systemctl start mysqld
VALIDATE $? "Starting Mysql server"

mysql_secure_installation --set-root-pass ExpenseApp@1
VALIDATE $? "Setting up the Root Password"