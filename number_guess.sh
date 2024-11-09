#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

#get username
ENTRY_POINT () {
  echo "Enter your username:"
  read USERNAME_INPUT

  #get user from db
  USER=$($PSQL "SELECT * FROM user_data WHERE username='$USERNAME_INPUT'")
  #if doesnt exist, create new user
  if [[ -z $USER ]]
  then
    echo "Welcome, $USERNAME_INPUT! It looks like this is your first time here."
    USER_INSERT=$($PSQL "INSERT INTO user_data(username) VALUES('$USERNAME_INPUT')")
    USER_ID=$($PSQL "SELECT user_id FROM user_data WHERE username='$USERNAME_INPUT'")
  else
    IFS="|" read USER_ID USERNAME GAMES_PLAYED BEST_SCORE <<< "$(echo $USER)"
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_SCORE guesses."
  fi

  GUESSING_GAME $USER_ID
}

#guessing the correct number
GUESSING_GAME () {
  USER_ID=$1
  USER_GUESSES=0
  #generate random number
  RANDOM_NUMBER=$((1 + $RANDOM % 1000))
  echo "Guess the secret number between 1 and 1000:"

  #get user guess
  read USER_INPUT

  while [[ $USER_INPUT != $RANDOM_NUMBER ]]
  do
    if [[ ! $USER_INPUT =~ ^[0-9]+$ ]]
    then
      echo "That is not an integer, guess again:"
      read USER_INPUT
    elif (( USER_INPUT > RANDOM_NUMBER ))
    then
      USER_GUESSES=$((USER_GUESSES + 1))
      echo "It's lower than that, guess again:"
      read USER_INPUT
    elif (( USER_INPUT < RANDOM_NUMBER ))
    then
      USER_GUESSES=$((USER_GUESSES + 1))
      echo "It's higher than that, guess again:"
      read USER_INPUT
    fi
  done

  USER_GUESSES=$((USER_GUESSES + 1))
  echo "You guessed it in $USER_GUESSES tries. The secret number was $RANDOM_NUMBER. Nice job!"

  #update values in db
  UPDATE_GAMES_PLAYED=$($PSQL "UPDATE user_data SET games_played = games_played + 1 WHERE user_id=$USER_ID")

  #update best_score
  OLD_SCORE=$($PSQL "SELECT best_game FROM user_data WHERE user_id = $USER_ID")
  if [[ -z $OLD_SCORE ]]
  then
    SET_NEW_SCORE=$($PSQL "UPDATE user_data SET best_game = $USER_GUESSES WHERE user_id = $USER_ID")
  else
    if [[ $USER_GUESSES < $OLD_SCORE ]]
    then
      UPDATE_SCORE=$($PSQL "UPDATE user_data SET best_game = $USER_GUESSES WHERE user_id = $USER_ID")
    fi
  fi
}

ENTRY_POINT