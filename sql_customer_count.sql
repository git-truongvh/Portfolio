--This query builds a table that shows the a specific questionnaire answer for every order in the last year. During a lunch and learn, a business partner mentioned she wanted to know how often customers were selecting the company to
-- be their RA. She initially wanted to have her team members manually tally the orders as they went through the workflow. However, I advised her that we could simply query for that information in our database. This query was constructed
--live and in five minutes to not just answer the business problem but also remove a manual task from the business team. 

Select
    OrderNumber,
    ProcessingNumber,
    State,
    Who_is_RA, -- the alias for the value that the business is interested in
    Date_Created
From
--I first subquery the FIELDANSWER table which contaisn all questionnaire field answers for all orders in a long data format. Since I am only interested in one field, I can filter for only that field.
    (
      Select
          FKUSERORDER as ProcessingNumber,
          SVALUE as Who_is_RA --the answer we are looking for.
      From
          "FIELDANSWER"
      Where
          FKQUESTIONNAIREFIELD = 8253 -- the questionnaire field that is associated with the answer we are looking for.
    ) as RAInfo
--I join onto ORDERITEMS in order to get information such as the customer order number, the date created, and the state the order was placed in
    inner join
        (
        Select
          FKORDER as OrderNumber,
          orderitem.DTCREATED as Date_Created,
          SSTATE as State,
          FKUSERORDER
        From
          "ORDERITEM" as orderitem
          inner join "STATE" as StateTable on PKSTATE = FKSTATE
        --Optional code for filtering for a specific state
		--Where 
          --State = 'California'
        ) as orderDetails on orderDetails.FKUSERORDER = RAInfo.ProcessingNumber
Where
    Date_Created between dateadd(Year, -1, CURRENT_DATE()) and CURRENT_DATE()
