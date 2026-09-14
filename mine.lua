-- GameGuardian Script
-- Display Subscription Renewal Message

function main()
    -- Display the message in English
    local message = "Please renew your subscription to continue using this script."
    local title = "Subscription Expired"
    
    -- Show the dialog with OK button
    gg.alert(message, title)
    
    -- Optional: Show a more detailed message
    -- gg.alert("Your subscription has expired.\n\nPlease renew your subscription to continue.\n\nThank you!", "Subscription Required")
    
    -- Exit the script after showing the message
    os.exit()
end

-- Run the main function
main()
