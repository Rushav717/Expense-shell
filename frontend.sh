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

mkdir -p $LOG_FOLDER
echo "Script Started excecuted at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf install nginx -y 
VALIDATE $? "Installing nginx server"

systemctl enable nginx
VALIDATE $? "Enabling the nginx"

systemctl start nginx
VALIDATE $? "Start the nginx"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "Removing the old code"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip
VALIDATE $? "Downloading the frontend latest code"

cd /usr/share/nginx/html
VALIDATE $? "Moving to html directory"

unzip /tmp/frontend.zip
VALIDATE $? "Unzip the code"

cp /home/ec2-user/Expense-shell/expense.conf /etc/nginx/default.d/expense.conf

systemctl restart nginx
VALIDATE $? "Restarting nginx"

