/*
Question #1:  What are the unique states values available in the customer data? 
Count the number of customers associated to each state.
Expected columns: state, total_customers
*/

-- q1 solution : 	 --solution with a simple query, can be done with temp table but i choose to keep it simple
select distinct (state), count (distinct customer_id)      
from customers                                              
group by distinct (state);


/*
Question #2: It looks like the state data is not 100% clean and your manager already one issue:
 “US State” customers should be assigned to California.
What is the total number of orders that have been completed for every state? 
Only include orders for which customer data is available.
Expected columns: clean_state, total_completed_orders
*/

-- q2 solution:

	--temp table to assign data from US State to California
with cleaned_state as 	(select *, case when state in ('US State') then 'California'          
                                    else state end as clean_state 
			from customers),
	
    	--temp table to get the complete orders joining cleaned states 
orders_completed as 	(select * from orders o join cleaned_state cs                      
                                    on o.user_id = cs.customer_id where status in ('Complete'))
	
     	--main table to get complete orders by cleaned states excluding Customer Null values
select clean_state, count (distinct (order_id)) as total_complete_orders                    
from orders_completed                                                                       
where customer_id is not null
group by clean_state;

/*
Question #3: After excluding some orders since the customer information was not available, 
your manager gets back to and stresses what we can never presented a number that is missing any 
orders even if our customer data is bad.
What is the total number of orders, number of Nike Official orders, and number of Nike Vintage 
orders that are completed by every state?
If customer data is missing, you can assign the records to ‘Missing Data’.
Expected columns: clean_state, total_completed_orders, official_completed_orders, 
vintage_completed_orders
*/

-- q3 solution:

	--temp table to assign data from US State to California
with cleaned_state as 	(select *,    case when state in ('US State') then 'California'      
                                    else state end as clean_state from customers),

	--temp table to get the complete orders joining cleaned states
orders_completed as    (select * from orders o                                             
                            left join cleaned_state cs on o.user_id = cs.customer_id 
			where status in ('Complete'))

	 --main table to do the calculations required grouped x clean_state
select coalesce (clean_state, 'Missing Data') as clean_state,                              
	count (distinct oc.order_id) as total_completed_orders,
        count (distinct oi.order_id) as official_completed_orders,
        count (distinct oiv.order_id) as vintage_completed_orders
from orders_completed oc   	left join order_items oi on oc.order_id = oi.order_id
 				left join order_items_vintage oiv on oc.order_id = oiv.order_id
group by clean_state order by clean_state asc; 

/*
Question #4: When reviewing sales performance, there is one metric we can never forget; revenue. 
Reuse the query you created in question 3 and add the revenue (aggregate of the sales price) 
to your table:  (1) Total revenue for the all orders (not just the completed!)
Expected columns: clean_state, total_completed_orders, official_completed_orders, 
vintage_completed_orders, total_revenue.
*/

-- q4 solution:

	--temp table to assign data from US State to California
with cleaned_state as 	(select *, case when state in ('US State') then 'California'                          
                                    else state end as clean_state from customers),

	--temp table to get Nike Official + Nike Vintage bizz
total_bizz as 		(select * from order_items union all select * from order_items_vintage),
	
	--temp table getting total rev from total bizz x state, assigning Null values to Missing Data
revenues_state as 	(select coalesce (cs.clean_state, 'Missing Data') as clean_state,                    
                        	sum (tb.sale_price) as total_rev
                        from total_bizz tb left join cleaned_state cs on tb.user_id = cs.customer_id
                        group by cs.clean_state),
	
	--temp table doing the required calculations x complete orders x clean state, assigning also Null values to Missing Data 
completed_orders as    (select coalesce (cs.clean_state, 'Missing Data') as clean_state,           
    				count (distinct o.order_id) as total_completed_orders,                    
				count (distinct oi.order_id) as official_completed_orders,
    				count (distinct oiv.order_id) as vintage_completed_orders 
                            from orders o 	left join order_items oi on oi.order_id = o.order_id
                          			left join order_items_vintage oiv on o.order_id = oiv.order_id
 						left join cleaned_state cs on o.user_id = cs.customer_id
                            where status = 'Complete' group by cs.clean_state )

	--main table to show the results
select co.clean_state, total_completed_orders, official_completed_orders, vintage_completed_orders, total_rev   
from  completed_orders co join revenues_state rs on co.clean_state = rs.clean_state
order by co.clean_state;

/*
Question #5: The leadership team is also interested in understanding the number of order items 
that get returned. Reuse the query of question 4 and add an additional metric to the table: 
(1) Number of order items that have been returned (items where the return date is populated)
Expected columns: clean_state, total_completed_orders, official_completed_orders, vintage_completed_orders, 
total_revenue,returned_items
*/

-- q5 solution:

	 --temp table to assign data from US State to California
with cleaned_state as 	(select *,    case when state in ('US State') then 'California'                             
                                    else state end as clean_state from customers),
	--temp table to get Nike Official + Nike Vintage bizz
total_bizz as 		(select * from order_items union all select * from order_items_vintage),  
	
	 --temp table getting total rev from total bizz x state, assigning Null values to Missing Data
revenues_state as 	(select coalesce (cs.clean_state, 'Missing Data') as clean_state,                       
                        	sum (tb.sale_price) as total_rev
                	from total_bizz tb left join cleaned_state cs on tb.user_id = cs.customer_id
                        group by cs.clean_state),
	
--temp table doing the required calculations x complete orders x clean state, assigning also Null values to Missing Data
completed_orders as    (select coalesce (cs.clean_state, 'Missing Data') as clean_state,                   
    				count (distinct o.order_id) as total_completed_orders,                     
				count (distinct oi.order_id) as official_completed_orders,
    				count (distinct oiv.order_id) as vintage_completed_orders 
                 	from orders o 	left join order_items oi on oi.order_id = o.order_id
                          		left join order_items_vintage oiv on o.order_id = oiv.order_id
 					left join cleaned_state cs on o.user_id = cs.customer_id
                        where status = 'Complete' group by cs.clean_state ),
	
	--temp table calculating nr. items returned
returned as   (select coalesce (cs.clean_state, 'Missing Data') as clean_state,                           
                    count (tb.returned_at) as returned_items 
                from total_bizz tb left join cleaned_state cs on tb.user_id = cs.customer_id
                where tb.returned_at is not null group by cs.clean_state)  
	
	--main table showing the results
select  r.clean_state, total_completed_orders, official_completed_orders, vintage_completed_orders, total_rev,  
        returned_items 
from  completed_orders co   	join revenues_state rs on co.clean_state = rs.clean_state
		        	join returned r on co.clean_state = r.clean_state
order by r.clean_state;

/*
Question #6: When looking at the number of returned items by itself, it is hard to understand what number of 
returned items is acceptable. This is mainly caused by the fact that we don’t have a benchmark at the moment.
Because of that, it is valuable to add an additional metric that looks at the percentage of returned order
items divided by the total order items, we can call this the return rate.
Reuse the query of question 5 and integrate the return rate into your table.
Expected columns: clean_state, total_completed_orders, official_completed_orders, vintage_completed_orders, 
total_revenue,returned_items,return_rate
*/

-- q6 solution:

	--temp table to assign data from US State to California
with cleaned_state as (select *,    case when state in ('US State') then 'California'                      
                                    else state end as clean_state from customers),
	
        --temp table to get Nike Official + Nike Vintage bizz               
total_bizz as (select * from order_items union all select * from order_items_vintage),
	
 	--temp table getting total rev from total bizz x state, assigning Null values to Missing Data    
revenues_state as 	(select coalesce (cs.clean_state, 'Missing Data') as clean_state,                
                        	sum (tb.sale_price) as total_rev
                	from total_bizz tb left join cleaned_state cs on tb.user_id = cs.customer_id
                        group by cs.clean_state),
	
--temp table doing the required calculations x complete orders x clean state, assigning also Null values to Missing Data                        
completed_orders as    (select coalesce (cs.clean_state, 'Missing Data') as clean_state,           
    				count (distinct o.order_id) as total_completed_orders,              
				count (distinct oi.order_id) as official_completed_orders,
    				count (distinct oiv.order_id) as vintage_completed_orders 
                 	from orders o 	left join order_items oi on oi.order_id = o.order_id
                          		left join order_items_vintage oiv on o.order_id = oiv.order_id
 					left join cleaned_state cs on o.user_id = cs.customer_id
                          where status = 'Complete' group by cs.clean_state ),
	
        --temp table calculating nr. items returned                  
returned as   (select coalesce (cs.clean_state, 'Missing Data') as clean_state,                  
                    count (tb.returned_at) as returned_items 
                from total_bizz tb left join cleaned_state cs on tb.user_id = cs.customer_id
                where tb.returned_at is not null group by cs.clean_state),
	
	 --temp table calculating total_orders x cleaned_state      
 r_rate as     (select coalesce (cs.clean_state, 'Missing Data') as clean_state,                      
                    cast (count (tb.order_id) as float ) as total_orders
                from total_bizz tb left join cleaned_state cs on tb.user_id = cs.customer_id
                group by cs.clean_state)
	
	--main table showing the results + calculating return_rate                         
select rr.clean_state, total_completed_orders, official_completed_orders, vintage_completed_orders, total_rev,      
returned_items, r.returned_items / rr.total_orders as return_rate
from  completed_orders co   join revenues_state rs on co.clean_state = rs.clean_state
						    join returned r on co.clean_state = r.clean_state
                 			join r_rate rr on co.clean_state = rr.clean_state
order by rr.clean_state;
