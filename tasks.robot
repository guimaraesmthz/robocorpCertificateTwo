*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
...    

Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library    RPA.Archive

*** Keywords ***
Get orders
    Download      https://robotsparebinindustries.com/orders.csv                                               overwrite=True                             target_file=C:\Users\Pichau\Downloads
    ${table}=     Read table from CSV                                                                          C:/Users/Pichau/Downloads/orders.csv
    [Return]      ${table}

Close the annoying modal
    Click Element If Visible                                                                                   xpath=//button[text()="OK"]        

Store the receipt a PDF file
    [Arguments]                     ${OrderNumber}
    
    ${receipt}=                     Run Keyword And Return Status          Get Text     //p[@class="badge badge-success"]
    IF    "${receipt}" == "True"
        Take a screenshot of the robot image    ${OrderNumber}             
        ${receipt}=                 Get Text     //p[@class="badge badge-success"]
        Html To Pdf                 Receipt: ${receipt}                                             ./output/receipts/receipt-order${OrderNumber}.pdf
        ${fileList}=                Create List                                                     ./output/screenshots/screenshot-receipt-order${OrderNumber}.png
        Add Files To Pdf            ${fileList}                                                     ./output/receipts/receipt-order${OrderNumber}.pdf                append=True
        Log To Console              Order creation passed.
    ELSE
        Log To Console              Order creation failed.
    END
    
Take a screenshot of the robot image
    [Arguments]                    ${OrderNumber}

    ${screenshot}=                 Screenshot                    //div[@id="receipt"]                ./output/screenshots/screenshot-receipt-order${OrderNumber}.png    

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    
    ${orders}=                      Get orders
    ${rows}    ${columns}=          Get Table Dimensions         ${orders} 
    
    Open Browser                    https://robotsparebinindustries.com/#/robot-order    browser=chrome    
    ${rows}=                        Evaluate                     ${rows}-1

    FOR    ${counter}    IN RANGE    0    ${rows}    1
        ${actRow}=                  Get Table Row                ${orders}       ${counter}        as_list=True
        
        Close the annoying modal
        Select From List By Value       //select[@id="head"]                                                  ${actRow[1]}
        Click Element If Visible        //input[@class="form-check-input" and @value="${actRow[2]}"]
        Input Text                      //input[@placeholder="Enter the part number for the legs"]            ${actRow[3]}
        Input Text                      //input[@placeholder="Shipping address"]                              ${actRow[4]}    
        Click Element If Visible        //button[@id="order"]
        Store the receipt a PDF file    ${actRow[0]}
    
        IF    ${counter} != 19
            Click Element If Visible    //button[@id="order-another"]
        ELSE
            Close Browser               
        END

    END

    Archive Folder With Zip            ./output            output.zip            recursive=True
   