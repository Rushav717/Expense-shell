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

dnf module disable nodejs -y &>>$LOG_FILE_NAME 
VALIDATE $? "Disabling existing nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling the nodejs 20"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing the NodeJS 20"

id expense
if [ $? -ne 0 ]
then
 useradd expense &>>$LOG_FILE_NAME
 VALIDATE $? "Adding the User"
else
 echo -e "Expense User already exists .... $Y skipping $N"
fi

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading the Backend code"

mkdir -p /app &>>$LOG_FILE_NAME
VALIDATE $? "Creating app directory"

cd /app
rm -rf /app/*

unzip /tmp/backend.zip &>>$LOG_FILE_NAME
VALIDATE $? "Unzipping backend"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/Expense-shell/backend.service /etc/systemd/system/backend.service

#Praparing mysql schema

dnf install mysql -y &>> $LOG_FILE_NAME
VALIDATE $? "Installing mysql client"

mysql -h mysql.rushhav.fun -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "Settimg up the transaction Schema & Tables"


systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "Daemon reload"

systemctl start backend &>>$LOG_FILE_NAME
VALIDATE $? "Start the backend"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enabling the backend"





