#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=salon --no-align --tuples-only -c"

echo -e "\n~~~~~ MY SALON ~~~~~\n"

DISPLAY_LIST_OF_SERVICES () {
  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")
  echo "$SERVICES" | while IFS="|" read ID SERVICE
  do
    echo "$ID) $SERVICE"
  done
}

MAIN_MENU () {
  # Display messaga above the services list
  if [[ $1 ]]
  then
    echo -e "$1"
  fi

  DISPLAY_LIST_OF_SERVICES

  read SERVICE_ID_SELECTED
  
  # Check if entered a number
  if [[ ! $SERVICE_ID_SELECTED =~ ^[1-9]+$ ]]
  then
    MAIN_MENU "\nI could not find that service. What would you like today?"
  else
    # Check if service exists
    SERVICE_NAME_SELECTED=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")
    if [[ -z $SERVICE_NAME_SELECTED ]]
    then
      MAIN_MENU "\nI could not find that service. What would you like today?"
    else
      echo -e "\nWhat's your phone number?"
      read CUSTOMER_PHONE
      # Check if phone format is valid
      if [[ ! $CUSTOMER_PHONE =~ ^([0-9]+-)+[0-9]+$ ]]
      then
        MAIN_MENU "\nInvalid phone format. What would you like today?"
      else
        # Get customer info
        CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")

        # Customer not found
        if [[ -z $CUSTOMER_NAME ]]
        then
          echo -e "\nI don't have a record for that phone number, what's your name?"
          read CUSTOMER_NAME
          # Check if name is valid
          if [[ ! $CUSTOMER_NAME =~ ^[A-Za-z]+$ ]]
          then
            MAIN_MENU "\nInvalid name format. What would you like today?"
          else
            # Add customer
            INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES ('$CUSTOMER_NAME','$CUSTOMER_PHONE')")
          fi
        fi
        # Customer found
        # Get customer ID
        CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

        # Make appointment
        echo -e "\nWhat time would you like your $SERVICE_NAME_SELECTED, $CUSTOMER_NAME?"
        read SERVICE_TIME
        # Check if time is valid
        if [[ ! $SERVICE_TIME =~ ^([0-2][0-9]:[0-5][0-9])|([0-1][0-9](am|pm))$ ]]
        then
          MAIN_MENU "\nInvalid time format. What would you like today?"
        else
        # Save appointment
        SAVE_APPIONTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
        echo -e "\nI have put you down for a $SERVICE_NAME_SELECTED at $SERVICE_TIME, $CUSTOMER_NAME.\n"
        fi
      fi
    fi
  fi
}



MAIN_MENU "Welcome to My Salon. How can I help you?\n"