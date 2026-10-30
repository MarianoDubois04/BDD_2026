USE sakila;
--4) 
update customer
set premium_customer = 'T'
where customer_id in (select distinct cur.customer_id from (select distinct c.customer_id, sum(p.amount) as total from customer c
	join payment p 
	on p.customer_id = c.customer_id
	group by c.customer_id
	order by total desc
	limit 10) as cur)

--5)
select c.name, count(fc.category_id) cantidad from category c
join film_category fc
on c.category_id = fc.category_id
group by c.name
order by cantidad desc

--6) 
select min(payment_date) primer_pago, max(payment_date) ultimo_pago from payment

--7) 
--forma 1) separando meses de años ej jun 2025, jun 2026, jun 2027
select date_format(p.payment_date, '%Y-%m') as mes, avg(p.amount) as promedio
from payment p
group by date_format(p.payment_date, '%Y-%m')
order by mes;

--forma 2) agrupando meses de distintos años
select monthname(p.payment_date) as mes, avg(p.amount) as promedio
from payment p
group by month(p.payment_date), monthname(p.payment_date)
order by month(p.payment_date);

--8) 
select a.district distrito, count(r.rental_id) cantidad from address a
join store s on s.address_id = a.address_id
join inventory i on i.store_id = s.store_id
join rental r on r.inventory_id = i.inventory_id
group by distrito 
order by cantidad desc

--10)
DELIMITER $$

create trigger update_stock
after insert on rental
for each row
begin
	update inventory
	set stock = stock - 1
	where inventory_id = NEW.inventory_id;
end$$

DELIMITER ;

--11)
create table fines(
	fine_id int primary key,
	rental_id int,
	amount numeric(2,2)
);

alter table fines add constraint fk_rental_id foreign key(rental_id) references rental(rental_id);

--12)
delimiter $$
create procedure check_date_and_fine()
begin
	insert into fines (rental_id, amount)
	select rental_id,
	       (to_days(return_date) - to_days(rental_date)) * 1.5
	from rental
	where (to_days(return_date) - to_days(rental_date)) > 3;
end$$

delimiter ;