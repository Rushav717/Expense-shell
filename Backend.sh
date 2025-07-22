#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%T)
LOG_FILE_NAME="$LOG_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
      echo -e "$2 ... $R FAILURE $N"
      exit 1
    else
      echo -e "$2 ... $G Success $N"
    fi
}


CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
      echo "ERROR:: Sudo access is Required to execute the script"
      exit 1
    fi
}

echo "Script Started excecuted at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf module disable nodejs -y
VALIDATE $? "Disabling existing nodejs"

dnf module enable nodejs:20 -y
VALIDATE $? "Enabling the nodejs 20"

dnf install nodejs -y
VALIDATE $? "Installing the NodeJS 20"

useradd expense
VALIDATE $? "Adding the User"

mkdir /app
VALIDATE $? "Creating the app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip
VALIDATE $? "Downloading the Backend code"

cd /app

npm install
VALIDATE $? "Installing dependecies"

cp /home/ec2-user/Expense-shell/backend.service /etc/systemd/system/backend.service

#Praparing mysql schema

dnf install mysql -y &>> $LOG_FILE_NAME
VALIDATE $? "Installing mysql client"

mysql -h mysql.rushhav.fun -uroot -pExpenseApp@1 < /app/schema/backend.sql
VALIDATE $? "Settimg up the transaction Schema & Tables"


systemctl daemon-reload
VALIDATE $? "Daemon reload"

systemctl start backend
VALIDATE $? "Start the backend"

systemctl enable backend
VALIDATE $? "Enabling the backend"





