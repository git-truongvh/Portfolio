--This query builds a table that displays a pair of questionnaire answers for orders within the past year and an analysis if they were ok or not. The business was seeing that there were orders with an impossible answer combination
--where there were multiple owners/members but the questionnaire listed a follow up answer of being managed "By its single member". These answers were autopopulated in the background based on the customer's selection
--This table helps identified those orders for follow up research to identify trends on similarities. From researching the "Problem" orders, the pattern was identified that only certain owner types were being tabulated.
--Additionally, since this table returned the whole population of orders, it was shown that this was an issue that only occurred in 1% of orders in the last year.

--This query was done in SNOWFLAKE

Select
    state,
    FKORDER as OrderNumber,
    numFilter.FKUSERORDER as ProcessingNumber,
    Case when (numOwners != '1 owner' and managedBy = 'By its single member.') then 'Problem' Else 'Ok' End as Diagnosis, --This line specifically checks for the impossible answer combination and if found set the value in this row to be "Problem"
    numOwners,
    managedBy,
    Date_Created,
	ORCO_CATEGORY1
	ORCO_REASON1,
	ORCO_REASON2
From
	--FIELDANSWER stores all the answers to the questionnaire in a long data format for an order with each row being a specific question answer. This meant each order had multiple rows.
	--I needed to look at specifically 2 questionnaire answer fields for all orders. However, the data is saved with two column,  FKQUESTIONNAIREFIELD as the question and SVALUE as the answer.
	--Since I technically wanted to see 2 SVALUES in the same row, I decided to subquery FIELDANSWER twice to create two tables to do an inner join on so that I can change the long data format to a wide data format.
    (
    Select
      FKUSERORDER, --Internal Processing Number
      SVALUE as numOwners --Answer for the number of owners 
    From
        "FIELDANSWER"
    Where
        FKQUESTIONNAIREFIELD = 292199 --the question field paired with the SVALUE for the number of owners
        --These commented out lines are additional code to return the exact problem conditions
		--And 
        --SVALUE != '1 owner'
    ) as numFilter --The first table created by the subquery contains all of the answers for the first question "number of owners?"
    inner join
    (
    Select
        FKUSERORDER,
        SVALUE as managedBy --Answer for who is managing the Business
    From
        "FIELDANSWER"
    Where
        FKQUESTIONNAIREFIELD = 8261 --the question field paired with the SVALUE for the Business manager
        --These commented out lines are additional code to return the exact problem conditions
		--And
        --SVALUE = 'By its single member.'
    ) as mgmt on mgmt.FKUSERORDER = numFilter.FKUSERORDER --I joined the two tables by the processing number to create a single table containing the relevant answers as wide data
    --I wanted to also show to the Business stakeholders if these orders were ever manually flagged for a problem. ORCOTRANSACTION is a table containing records for when a processor flagged an order for an intervention and what their reason was.
	--Since ORCOTRANSACTION catalogue manual interventions, not all orders were going to appear in the table so a left join allowed me to keep all the orders that weren't flagged while still getting all the details I could for orders that were flagged.
	left join
    (
    Select
      Distinct
      FKUSERORDER,
	  ORCO_CATEGORY1, --This datapoint records the problem category that the processor flagged the order for
	  ORCO_REASON1, --This datapoint records the more specific reason within the category
	  ORCO_REASON2 --This datapoint records the secondary reason
    From
       "ORCOTRANSACTIONS"
    ) as orco on orco.FKUSERORDER = numFilter.FKUSERORDER
    --Unfortunately, the FIELDANSWER table does not contain information such as the State the order is from, Customer Order Number, or the order create date. So in order to have that information available for a business stakeholder
	--I queried the ORDERITEMS table that does contain customer order number and order create date. However, the state information in ORDERITEMS is recorded in a numeric value. In order to see what the numeric value translate to
	--I needed to join to the STATE table in order to get the user friendly name for the State.
	inner join
        (
        Select
          FKORDER,
          orderitem.DTCREATED as Date_Created,
          SSTATE as State, --SSTATE is the userfriend name associated to PKSTATE
          FKUSERORDER
        From
          "ORDERITEM" as orderitem
          inner join "STATE" as StateTable on PKSTATE = FKSTATE --PKSTATE is the primary key in STATE and FKSTATE is the foreign key in ORDERITEMS. By joining on that, I can get the SSTATE value associated with the PKSTATE 
        --More optional code for a specific use case where we only wanted to look at California orders
		--Where 
          --State = 'California'
        ) as orderDetails on orderDetails.FKUSERORDER = numFilter.FKUSERORDER
Where
    Date_Created between dateadd(Year, -1, CURRENT_DATE()) and CURRENT_DATE()
Order by
    Date_Created desc
