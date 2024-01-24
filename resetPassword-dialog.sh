#!/bin/zsh

# Path to SwiftDialog
dialogPath='/usr/local/bin/dialog'

# Function to check if a password meets the criteria
check_password() {
    local password=$1

    # Check if the password length is greater than 14 characters
    if [ ${#password} -le 14 ]; then
        return 1
    fi

    # Check if the password contains at least one uppercase letter, one lowercase letter, one digit, and one special character
    if ! [[ "$password" =~ [A-Z] && "$password" =~ [a-z] && "$password" =~ [0-9] && "$password" =~ [\W_] ]]; then
        return 1
    fi

    return 0
}

# Welcome experience
welcomeTitle="Change Password"
welcomeBody="Let's change your password."
errorMessage="Password does not meet the criteria. Please try again."

# Get a list of users excluding built-in users, admin.*, and daemon
users=($(/usr/bin/dscl . -list /Users | grep -v '^_' | grep -v '^admin\.' | grep -v '^daemon' | grep -v '^nobody'| grep -v '^root'))
users=($(echo $users |  tr ' ' ','))

# Set IFS to comma to split the string
IFS=',' read -r user1 user2 user3 <<< "$users"

# Access the first value in the array
first_user="$user1"

selectedUser=$("$dialogPath" \
--title "$welcomeTitle" \
--message "Select which user to change the password of" \
--selecttitle "User" \
--ontop \
--blurscreen \
--position top \
--selectvalues "$users" \
--selectdefault "$first_user")

selectedOption=$(echo "$selectedUser" | awk -F'"' '/SelectedOption/ {print $4}')

# Textfield label
textFieldLabel="Enter New Password"
textFieldLabel2="Re-Enter New Password"
textFieldLabel3="Enter user's current Password"

sudo pwpolicy -u $selectedOption -setpolicy "newPasswordRequired=0"

while true; do
    # Prompt user for password
    current_password=$("$dialogPath" \
        --output-fd 1 \
        --ontop \
        -blurscreen \
        --clear \
        --title "$welcomeTitle" \
        --message "$welcomeBody for user: $selectedOption" \
        --textfield "$textFieldLabel3",secure,required 10 30)
    
    current_password=$(echo "$current_password" | sed 's/.*Password : //')

    # Check if the user exists
    if id "$selectedOption" &>/dev/null; then
        # Verify the password using openssl
        if dscl . -authonly "$selectedOption" "$current_password" &>/dev/null; then
            echo "Password is correct for user $selectedOption."
            break
        else
            echo "Incorrect password for $selectedOption."
            "$dialogPath" \
                --message "Incorrect password for $selectedOption, please try again." 10 30 \
                --ontop
        fi
    else
        echo "User $selectedOption not found."
    fi

done

    while true; do
    # Prompt user for password
    password=$("$dialogPath" \
        --output-fd 1 \
        --ontop \
        --clear \
        --title "$welcomeTitle" \
        --message "$welcomeBody for user: $selectedOption" \
        --textfield "$textFieldLabel",secure,required 10 30)


    # Check if the password meets the criteria
    if check_password "$password"; then
        # Prompt user for password confirmation
        passwordConfirmation=$("$dialogPath" \
            --output-fd 1 \
            --ontop \
            --clear \
            --title "$welcomeTitle" \
            --message "$welcomeBody for user: $selectedOption" \
            --textfield "$textFieldLabel2",secure,required 10 30)

        # Check if the passwords match
        password1=$(echo "$password" | sed 's/.*Password : //')
        password2=$(echo "$passwordConfirmation" | sed 's/.*Password : //')
        if [ "$password1" = "$password2" ]; then

            # Change the user's password
            echo "Changing password for user $selectedOption..."
            sudo dscl . passwd /Users/$selectedOption $current_password $password1
            security set-keychain-password -o $current_password -p  $password1 "/Users/$selectedOption/Library/Keychains/login.keychain"

            status=$?

            if [ $status == 0 ]; then
                echo "Password changed successfully for user: $selectedOption."
                "$dialogPath" \
                --message "Password changed successfully for user: $selectedOption." 10 30 \
                --ontop

            elif [ $status != 0 ]; then
                echo "An error was encountered while attempting to change the password. /usr/bin/dscl exited $status."
                "$dialogPath" \
                --message "An error was encountered while attempting to change the password. /usr/bin/dscl exited $status." 10 30 \
                --ontop

            fi
            exit $status
            break
        else
            # Display error message for password mismatch
            "$dialogPath" \
                --message "Passwords do not match. Please try again." 10 30 \
                --ontop
        fi
    else
        # Display error message for password criteria not met
        "$dialogPath" \
            --message "$errorMessage" 10 30 \
            --ontop
    fi
done
