if not exists(select * from sys.databases where name='orange_ams')
    create database orange_ams
GO

use orange_ams
GO


--DOWN
DROP PROCEDURE if EXISTS change_passenger_passport_no
DROP PROCEDURE if EXISTS change_employee_dept
DROP PROCEDURE if EXISTS pass_fl
DROP PROCEDURE if EXISTS emp_air_data_new
DROP PROCEDURE if EXISTS flight_data_new
if exists(select * from INFORMATION_SCHEMA.VIEWS
    WHERE TABLE_NAME='view_ontime_connecting_flights')
    DROP VIEW view_ontime_connecting_flights
if exists(select * from INFORMATION_SCHEMA.VIEWS
    WHERE TABLE_NAME='view_ontime_flights')
    DROP VIEW view_ontime_flights
if exists(select * from INFORMATION_SCHEMA.VIEWS
    WHERE TABLE_NAME='view_delayed_flights')
    DROP VIEW view_delayed_flights
if exists(select * from INFORMATION_SCHEMA.VIEWS
    WHERE TABLE_NAME='view_ticket_confirmed')
    DROP VIEW view_ticket_confirmed
if exists(select * from INFORMATION_SCHEMA.VIEWS
    WHERE TABLE_NAME='view_ticket_cancelled')
    DROP VIEW view_ticket_cancelled
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='fk_ticket_passenger_id')
    ALTER TABLE ticket DROP CONSTRAINT fk_ticket_passenger_id
DROP TABLE if EXISTS ticket
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='fk_employee_airport_name')
    ALTER TABLE employee DROP CONSTRAINT fk_employee_airport_name
DROP TABLE if EXISTS employee
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='fk_passenger_flight_code')
    ALTER TABLE passenger DROP CONSTRAINT fk_passenger_flight_code
DROP TABLE if EXISTS passenger
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='fk_flight_airline_id')
    ALTER TABLE flight DROP CONSTRAINT fk_flight_airline_id
DROP TABLE if EXISTS flight
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='fk_airport_city')
    ALTER TABLE airport DROP CONSTRAINT fk_airport_city
DROP TABLE if EXISTS airport
DROP TABLE if EXISTS airline
DROP TABLE if EXISTS city


GO
--UP Metadata
CREATE TABLE city
(
City_name VARCHAR(25) not null, 
City_state VARCHAR(25) not null,
City_country VARCHAR(10) not null,
constraint pk_city_city_name PRIMARY KEY(City_name)
)

ALTER table city alter COLUMN City_country VARCHAR(25) not null

CREATE table airline(
airline_id INT IDENTITY not null,
airline_name varchar (20) not null,
airline_code varchar (10) not null,
constraint pk_airline_airline_id PRIMARY KEY (airline_id)
)

create table airport(
    airport_name varchar (50) unique not null,
    airport_city varchar(25) not null,
    airport_state varchar (25) not null,
    airport_country varchar (25) not null,
    airport_airline_id int not null,
    constraint pk_airport_airport_name PRIMARY KEY (airport_name),
    CONSTRAINT fk_airport_city foreign Key (airport_city)
     REFERENCES city(City_name)   
)

ALTER table airport
DROP COLUMN airport_airline_id

CREATE TABLE flight(
    flight_code VARCHAR(10) unique not null,
    flight_source VARCHAR(20) not null,
    flight_destination VARCHAR(20) not null,
    flight_arrival DATETIME not null,
    flight_departure DATETIME not null,
    flight_status VARCHAR(10) not null,
    flight_type VARCHAR(10) not null,
    flight_duration float not null,
    flight_layover_time float,
    flight_no_of_stops INT not null,
    flight_airline_id INT not null,
    constraint pk_flight_flight_code PRIMARY KEY (flight_code),
    CONSTRAINT fk_flight_airline_id foreign Key (flight_airline_id)
     REFERENCES airline(airline_id)
)

create table passenger(
    passenger_id int UNIQUE IDENTITY not null,
    passenger_passport_no varchar(15) UNIQUE not null,
    passenger_firstname varchar(25) not null,
    passenger_lastname varchar(25) not null,
    passenger_address varchar(50) not null,
    passenger_phone int not null,
    passenger_email varchar(25) unique not null,
    passenger_age int not null,
    passenger_sex varchar(5) not null,
    passenger_flight_code varchar (10) not null, 
    constraint pk_passenger_passenger_id PRIMARY KEY(passenger_id),
    CONSTRAINT fk_passenger_flight_code foreign Key (passenger_flight_code)
     REFERENCES flight(flight_code)
)

ALTER table passenger 
alter COLUMN passenger_phone bigint not null

create table employee(
    employee_id int IDENTITY not null,
    employee_ssn VARCHAR(20) UNIQUE not null,
    employee_firstname varchar(25) not null,
    employee_lastname varchar(25) not null,
    employee_address varchar(50) not null,
    employee_phone int not null,
    employee_email varchar(25) unique not null,
    employee_age int not null,
    employee_sex varchar(5) not null,
    employee_job_type VARCHAR(20) not null,
    employee_salary int not null,
    employee_airport_name varchar(50) not null,
    constraint pk_employee_employee_id PRIMARY KEY(employee_id),
    CONSTRAINT fk_employee_airport_name foreign key(employee_airport_name)
     references airport(airport_name)
)

ALTER table employee 
alter COLUMN employee_phone bigint not null
ALTER table employee alter COLUMN employee_job_type varchar(50) not null

create table ticket(
    ticket_number INT IDENTITY (99700,1) not null,
    ticket_source VARCHAR(20) not null,
    ticket_destination VARCHAR(20) not null,
    ticket_date_of_travel DATETIME not NULL,
    ticket_seat_no VARCHAR(5),
    ticket_class varchar(10) not null,
    ticket_price money,
    ticket_passenger_id int UNIQUE not null,
    constraint pk_ticket_ticket_number PRIMARY KEY(ticket_number),
    CONSTRAINT fk_ticket_passenger_id foreign Key (ticket_passenger_id)
     REFERENCES passenger(passenger_id)
)

alter table ticket add ticket_date_of_booking datetime not null
alter table ticket add ticket_date_of_cancellation datetime
ALTER table ticket alter COLUMN ticket_class VARCHAR(25) not null

GO
-- Info to display on cancelled page
CREATE VIEW view_ticket_cancelled as
    select passenger_firstname + ' ' + passenger_lastname as passenger_name, passenger_email, passenger_flight_code, 
        ticket_number, ticket_source, ticket_destination, ticket_date_of_travel, ticket_date_of_cancellation
        from passenger 
            right join ticket on passenger_id = ticket_passenger_id
        where ticket_date_of_cancellation > 1900-01-01 
GO


-- Info to display on confirmed page
CREATE VIEW view_ticket_confirmed as
select passenger_firstname + ' ' + passenger_lastname as passenger_name, passenger_email, passenger_flight_code, 
       ticket_number, ticket_source, ticket_destination, ticket_date_of_travel, ticket_date_of_booking  
    from passenger 
        right join ticket on passenger_id = ticket_passenger_id
    where ticket_date_of_cancellation < 1901-01-01
GO

-- Delayed Flights
CREATE VIEW view_delayed_flights as
select flight_status, flight_code, flight_source, flight_destination,flight_departure
from flight
where flight_status='Delayed'
GO

-- On-time Flights
CREATE VIEW view_ontime_flights as
select flight_status, flight_code, flight_source, flight_destination,flight_departure
from flight
where flight_status='On-time'
GO

-- On-time and Connecting Flights
CREATE VIEW view_ontime_connecting_flights as
select flight_status, flight_code, flight_source, flight_destination,flight_departure
from flight
where flight_status='On-time' and flight_type='Connecting'
GO

-- Finding out source and destination of a flight
CREATE PROCEDURE flight_data_new (
    @fc varchar(10)
) as begin
    declare @fsc varchar(20)
    declare @fds varchar(20)
        select
            @fsc = flight_source,
            @fds = flight_destination
        from flight
        where @fc = flight_code
    print 'Flight ' + @fc + ' departs from ' + @fsc + 
          ' and arrives at ' + @fds 
  end

exec flight_data_new
    @fc = 'AI2014'
GO

-- Which airport does an employee work in?
CREATE PROCEDURE emp_air_data_new (
    @e_id int
)   as BEGIN
        declare @e_fn varchar(25)
        declare @e_ln varchar(25)
        declare @e_ap varchar(50)
            select
                @e_fn = employee_firstname,
                @e_ln = employee_lastname,
                @e_ap = employee_airport_name
            from employee
            where @e_id = employee_id
        print @e_fn + ' ' + @e_ln + ' works at ' + @e_ap
    end

exec emp_air_data_new
    @e_id = 8
GO

-- Which flight is a passenger travelling in?
CREATE PROCEDURE pass_fl (
    @p_id int
)   as BEGIN
        declare @p_fn varchar(25)
        declare @p_ln varchar(25)
        declare @p_fc varchar(50)
            select
                @p_fn = passenger_firstname,
                @p_ln = passenger_lastname,
                @p_fc = passenger_flight_code
            from passenger
            where @p_id = passenger_id
        print @p_fn + ' ' + @p_ln + ' is in Flight ' + @p_fc
    end

exec pass_fl
    @p_id = 33
GO

-- Updating Employee Job Type
create PROCEDURE change_employee_dept (
    @emp_id int, @emp_job_type varchar(20)
) as begin 
    update employee
        set employee_job_type = @emp_job_type
        where employee_id = @emp_id
  end  

exec change_employee_dept
    @emp_id = 1,
    @emp_job_type = 'TRAFFIC MONITOR'
GO

-- Updating Passenger Passport Number
create PROCEDURE change_passenger_passport_no (
    @pass_id int, @pass_pass_no varchar(10)
) as begin 
    update passenger
        set passenger_passport_no = @pass_pass_no
        where passenger_id = @pass_id
  end  

exec change_passenger_passport_no
    @pass_id = 31,
    @pass_pass_no = '34TF6791'
GO


GO
-- UP Data
INSERT INTO CITY (City_name, City_state, City_country) VALUES('Louisville','Kentucky','United States');
INSERT INTO CITY (City_name, City_state, City_country) VALUES ('Chandigarh','Chandigarh','India');
INSERT INTO CITY (City_name, City_state, City_country) VALUES ('Fort Worth','Texas','United States');
INSERT INTO CITY (City_name, City_state, City_country) VALUES('Delhi','Delhi','India');
INSERT INTO CITY (City_name, City_state, City_country) VALUES('Mumbai','Maharashtra','India');
INSERT INTO CITY (City_name, City_state, City_country) VALUES('San Francisco', 'California', 'United States');
INSERT INTO CITY (City_name, City_state, City_country) VALUES('Frankfurt','Hesse','Germany');
INSERT INTO CITY (City_name, City_state, City_country) VALUES('Houston','Texas','United States');
INSERT INTO CITY (City_name, City_state, City_country) VALUES('New York City','New York','United States');
INSERT INTO CITY (City_name, City_state, City_country) VALUES('Tampa', 'Florida', 'United States');

INSERT INTO AIRLINE (airline_name, airline_code) VALUES('American Airlines','AA');
INSERT INTO AIRLINE (airline_code, airline_name) VALUES('AI','Air India Limited');
INSERT INTO AIRLINE (airline_code, airline_name) VALUES('LH','Lufthansa');
INSERT INTO AIRLINE (airline_code, airline_name) VALUES('BA','British Airways');
INSERT INTO AIRLINE (airline_code, airline_name) VALUES('QR','Qatar Airways');
INSERT INTO AIRLINE (airline_code, airline_name) VALUES('9W','Jet Airways');
INSERT INTO AIRLINE (airline_code, airline_name) VALUES('EK','Emirates');
INSERT INTO AIRLINE (airline_code, airline_name) VALUES('EY','Ethiad Airways');

INSERT INTO AIRPORT (airport_name, airport_state, airport_country, airport_city) VALUES('Louisville International Airport','Kentucky','United States','Louisville');
INSERT INTO AIRPORT (airport_name, airport_state, airport_country, airport_city) VALUES('Chandigarh International Airport','Chandigarh','India','Chandigarh');
INSERT INTO AIRPORT (airport_name, airport_state, airport_country, airport_city) VALUES('Dallas/Fort Worth International Airport','Texas','United States','Fort Worth');
INSERT INTO AIRPORT (airport_name, airport_state, airport_country, airport_city) VALUES('Indira GandhiInternational Airport','Delhi','India','Delhi');
INSERT INTO AIRPORT (airport_name, airport_state, airport_country, airport_city) VALUES('Chhatrapati Shivaji International Airport','Maharashtra','India','Mumbai');
INSERT INTO AIRPORT (airport_name, airport_state, airport_country, airport_city) VALUES('San Francisco International Airport','California', 'United States','San Francisco');
INSERT INTO AIRPORT (airport_name, airport_state, airport_country, airport_city) VALUES('Frankfurt Airport','Hesse','Germany','Frankfurt');
INSERT INTO AIRPORT (airport_name, airport_state, airport_country, airport_city) VALUES('George Bush Intercontinental Airport','Texas','United States','Houston');
INSERT INTO AIRPORT (airport_name, airport_state, airport_country, airport_city) VALUES('John F. Kennedy International Airport','New York','United States','New York City');
INSERT INTO AIRPORT (airport_name, airport_state, airport_country, airport_city) VALUES('Tampa International Airport','Florida', 'United States','Tampa');

INSERT INTO FLIGHT(flight_code, flight_source, flight_destination, flight_arrival, flight_departure, flight_status, flight_duration, flight_type, flight_layover_time, flight_no_of_stops, flight_airline_id)
VALUES('AI2014','BOM','DFW','02:10','03:15','On-time',24.25,'Connecting',3,1,2);
INSERT INTO FLIGHT(flight_code, flight_source, flight_destination, flight_arrival, flight_departure, flight_status, flight_duration, flight_type, flight_layover_time, flight_no_of_stops, flight_airline_id)
VALUES('QR2305','BOM','DFW','13:00','13:55','Delayed',21.0,'Non-stop',0,0,5);
INSERT INTO FLIGHT(flight_code, flight_source, flight_destination, flight_arrival, flight_departure, flight_status, flight_duration, flight_type, flight_layover_time, flight_no_of_stops, flight_airline_id)
VALUES('EY1234','JFK','TPA','19:20','20:05','On-time',16.75,'Connecting',5,2,8);
INSERT INTO FLIGHT(flight_code, flight_source, flight_destination, flight_arrival, flight_departure, flight_status, flight_duration, flight_type, flight_layover_time, flight_no_of_stops, flight_airline_id)
VALUES('LH9876','JFK','BOM','05:50','06:35','On-time',18.50,'Non-stop',0,0,3);
INSERT INTO FLIGHT(flight_code, flight_source, flight_destination, flight_arrival, flight_departure, flight_status, flight_duration, flight_type, flight_layover_time, flight_no_of_stops, flight_airline_id)
VALUES('BA1689','FRA','DEL','10:20','10:55','On-time',14.0,'Non-stop',0,0,4);
INSERT INTO FLIGHT(flight_code, flight_source, flight_destination, flight_arrival, flight_departure, flight_status, flight_duration, flight_type, flight_layover_time, flight_no_of_stops, flight_airline_id)
VALUES('AA4367','SFO','FRA','18:10','18:55','On-time',21.15,'Non-stop',0,0,1);
INSERT INTO FLIGHT(flight_code, flight_source, flight_destination, flight_arrival, flight_departure, flight_status, flight_duration, flight_type, flight_layover_time, flight_no_of_stops, flight_airline_id)
VALUES('QR1902','IXC','IAH','22:00','22:50','Delayed',28.75,'Non-stop',5,1,5);
INSERT INTO FLIGHT(flight_code, flight_source, flight_destination, flight_arrival, flight_departure, flight_status, flight_duration, flight_type, flight_layover_time, flight_no_of_stops, flight_airline_id)
VALUES('BA3056','BOM','DFW','02:15','02:55','On-time',29.0,'Connecting',3,1,4);
INSERT INTO FLIGHT(flight_code, flight_source, flight_destination, flight_arrival, flight_departure, flight_status, flight_duration, flight_type, flight_layover_time, flight_no_of_stops, flight_airline_id)
VALUES('EK3456','BOM','SFO','18:50','19:40','On-time',15.5,'Non-stop',0,0,7);
INSERT INTO FLIGHT(flight_code, flight_source, flight_destination, flight_arrival, flight_departure, flight_status, flight_duration, flight_type, flight_layover_time, flight_no_of_stops, flight_airline_id)
VALUES('9W2334','IAH','DEL','23:00','13:45','On-time',13.25,'Direct',0,0,6);

INSERT INTO PASSENGER(passenger_passport_no, passenger_firstname, passenger_lastname, passenger_address, passenger_phone, passenger_age, passenger_sex, passenger_email, passenger_flight_code) 
VALUES('A1234568','ALEN','SMITH','2230 NORTHSIDE, APT 11, ALBANY, NY',8080367290,30,'M','asmith@ams.com','QR1902');
INSERT INTO PASSENGER(passenger_passport_no, passenger_firstname, passenger_lastname, passenger_address, passenger_phone, passenger_age, passenger_sex, passenger_email, passenger_flight_code) 
VALUES('B9876541','ANKITA','AHIR','3456 VIKAS APTS, APT 102,DOMBIVLI, INDIA',8080367280,26,'F','aahir@ams.com','EK3456');
INSERT INTO PASSENGER(passenger_passport_no, passenger_firstname, passenger_lastname, passenger_address, passenger_phone, passenger_age, passenger_sex, passenger_email, passenger_flight_code) 
VALUES('C2345698','KHYATI','MISHRA','7820 MCCALLUM COURTS, APT 234, AKRON, OH',8082267280,30,'F','kmishra@ams.com','BA1689');
INSERT INTO PASSENGER(passenger_passport_no, passenger_firstname, passenger_lastname, passenger_address, passenger_phone, passenger_age, passenger_sex, passenger_email, passenger_flight_code) 
VALUES('D1002004','ANKITA','PATIL','7720 MCCALLUM BLVD, APT 1082, DALLAS, TX',9080367266,23,'F','apatil@ams.com','AI2014');
INSERT INTO PASSENGER(passenger_passport_no, passenger_firstname, passenger_lastname, passenger_address, passenger_phone, passenger_age, passenger_sex, passenger_email, passenger_flight_code) 
VALUES('X9324666','TEJASHREE','PANDIT','9082 ESTAES OF RICHARDSON, RICHARDSON, TX',9004360125,28,'F','tpandit@ams.com','EY1234');
INSERT INTO PASSENGER(passenger_passport_no, passenger_firstname, passenger_lastname, passenger_address, passenger_phone, passenger_age, passenger_sex, passenger_email, passenger_flight_code) 
VALUES('B8765430','LAKSHMI','SHARMA','1110 FIR HILLS, APT 903, AKRON, OH',7666190505,30,'F','lsharma@ams.com','9W2334');
INSERT INTO PASSENGER(passenger_passport_no, passenger_firstname, passenger_lastname, passenger_address, passenger_phone, passenger_age, passenger_sex, passenger_email, passenger_flight_code) 
VALUES('J9801235','AKHILESH','JOSHI','345 CHATHAM COURTS, APT 678, MUMBAI, INDIA',9080369290,29,'M','ajoshi@ams.com','QR2305');
INSERT INTO PASSENGER(passenger_passport_no, passenger_firstname, passenger_lastname, passenger_address, passenger_phone, passenger_age, passenger_sex, passenger_email, passenger_flight_code) 
VALUES('A1122334','MANAN','LAKHANI','5589 CHTHAM REFLECTIONS, APT 349 HOUSTON, TX',9004335126,25,'F','mlakhani@ams.com','LH9876');
INSERT INTO PASSENGER(passenger_passport_no, passenger_firstname, passenger_lastname, passenger_address, passenger_phone, passenger_age, passenger_sex, passenger_email, passenger_flight_code) 
VALUES('Q1243567','KARAN','MOTANI','4444 FRANKFORD VILLA, APT 77, GUILDERLAND, NY',9727626643,22,'M','kmotani@ams.com','BA3056');
INSERT INTO PASSENGER(passenger_passport_no, passenger_firstname, passenger_lastname, passenger_address, passenger_phone, passenger_age, passenger_sex, passenger_email, passenger_flight_code) 
VALUES('S1243269','ROM','SOLANKI','7720 MCCALLUM BLVD, APT 2087, DALLAS, TX',9004568903,60,'M','rsolanki@ams.com','AA4367');
INSERT INTO PASSENGER(passenger_passport_no, passenger_firstname, passenger_lastname, passenger_address, passenger_phone, passenger_age, passenger_sex, passenger_email, passenger_flight_code) 
VALUES('E3277889','John','GATES','1234 BAKER APTS, APT 59, HESSE, GERMANY',9724569986,10,'M','jgates@ams.com','LH9876');
INSERT INTO PASSENGER(passenger_passport_no, passenger_firstname, passenger_lastname, passenger_address, passenger_phone, passenger_age, passenger_sex, passenger_email, passenger_flight_code) 
VALUES('K3212322','SARA','GOMES','6785 SPLITSVILLA, APT 34, MIAMI, FL',9024569226,15,'F','sgomes@ams.com','EY1234');
INSERT INTO PASSENGER(passenger_passport_no, passenger_firstname, passenger_lastname, passenger_address, passenger_phone, passenger_age, passenger_sex, passenger_email, passenger_flight_code) 
VALUES('P3452390','ALIA','BHAT','548 MARKET PLACE, SAN Francisco, CA',9734567800,10,'F','abhat@ams.com','BA3056');
INSERT INTO PASSENGER(passenger_passport_no, passenger_firstname, passenger_lastname, passenger_address, passenger_phone, passenger_age, passenger_sex, passenger_email, passenger_flight_code) 
VALUES('W7543336','JOHN','SMITH','6666 ROCK HILL, APT 2902, TAMPA, FL',4624569986,55,'M','jsmith@ams.com','9W2334');
INSERT INTO PASSENGER(passenger_passport_no, passenger_firstname, passenger_lastname, passenger_address, passenger_phone, passenger_age, passenger_sex, passenger_email, passenger_flight_code) 
VALUES('R8990566','RIA','GUPTA','3355 PALENCIA, APT 2065, MUMBAI, INDIA',4724512343,10,'M','agupta@ams.com','QR1902');

INSERT INTO EMPLOYEE(employee_ssn, employee_firstname, employee_lastname, employee_address, employee_phone, employee_age,employee_email, employee_sex, employee_job_type, employee_airport_name,employee_salary)
VALUES(123456789,'LINDA','GOODMAN','731 Fondren, Houston, TX',4356789345, 35,'lgoodman@ams.com', 'F','ADMINISTRATIVE SUPPORT','Louisville International Airport',50000);
INSERT INTO EMPLOYEE(employee_ssn, employee_firstname, employee_lastname, employee_address, employee_phone, employee_age,employee_email, employee_sex, employee_job_type, employee_airport_name,employee_salary)
VALUES(333445555,'JOHNY','PAUL','638 Voss, Houston, TX',9834561995, 40,'jpaul@ams.com', 'M','ADMINISTRATIVE SUPPORT','Louisville International Airport',50000);
INSERT INTO EMPLOYEE(employee_ssn, employee_firstname, employee_lastname, employee_address, employee_phone, employee_age,employee_email, employee_sex, employee_job_type, employee_airport_name,employee_salary)
VALUES(999887777,'JAMES','BOND','3321 Castle, Spring, TX',9834666995, 50,'jbond@ams.com', 'M','ENGINEER','Louisville International Airport',70000);
INSERT INTO EMPLOYEE(employee_ssn, employee_firstname, employee_lastname, employee_address, employee_phone, employee_age,employee_email, employee_sex, employee_job_type, employee_airport_name,employee_salary)
VALUES(987654321,'SHERLOCK','HOLMES','123 TOP HILL, SAN Francisco,CA',8089654321, 47,'sholmes@ams.com', 'M','TRAFFIC MONITOR','San Francisco International Airport',80000);
INSERT INTO EMPLOYEE(employee_ssn, employee_firstname, employee_lastname, employee_address, employee_phone, employee_age,employee_email, employee_sex, employee_job_type, employee_airport_name,employee_salary)
VALUES(666884444,'SHELDON','COOPER','345 CHERRY PARK, HESSE,GERMANY',1254678903, 55,'scooper@ams.com', 'M','TRAFFIC MONITOR','Frankfurt Airport',80000);
INSERT INTO EMPLOYEE(employee_ssn, employee_firstname, employee_lastname, employee_address, employee_phone, employee_age,employee_email, employee_sex, employee_job_type, employee_airport_name,employee_salary)
VALUES(453453453,'RAJ','SHARMA','345 FLOYDS, MUMBAI,INDIA',4326789031, 35,'rsharma@ams.com', 'M','AIRPORT AUTHORITY','Chhatrapati Shivaji International Airport',90000);
INSERT INTO EMPLOYEE(employee_ssn, employee_firstname, employee_lastname, employee_address, employee_phone, employee_age,employee_email, employee_sex, employee_job_type, employee_airport_name,employee_salary)
VALUES(987987987,'NIKITA','PAUL','110 SYNERGY PARK, DALLAS,TX',5678904325, 33,'npaul@ams.com', 'F','ENGINEER','Dallas/Fort Worth International Airport',70000);
INSERT INTO EMPLOYEE(employee_ssn, employee_firstname, employee_lastname, employee_address, employee_phone, employee_age,employee_email, employee_sex, employee_job_type, employee_airport_name,employee_salary)
VALUES(888665555,'SHUBHAM','GUPTA','567 CHANDANI CHOWK, DELHI, INDIA',8566778890, 39,'sgupta@ams.com', 'M','ADMINISTRATIVE SUPPORT','Indira GandhiInternational Airport',50000);
INSERT INTO EMPLOYEE(employee_ssn, employee_firstname, employee_lastname, employee_address, employee_phone, employee_age,employee_email, employee_sex, employee_job_type, employee_airport_name,employee_salary)
VALUES(125478909,'PRATIK','GOMES','334 VITRUVIAN PARK, ALBANY, NY',4444678903, 56,'pgomes@ams.com', 'M','TRAFFIC MONITOR','John F. Kennedy International Airport',80000);
INSERT INTO EMPLOYEE(employee_ssn, employee_firstname, employee_lastname, employee_address, employee_phone, employee_age,employee_email, employee_sex, employee_job_type, employee_airport_name,employee_salary)
VALUES(324567897,'ADIT','DESAI','987 SOMNATH, CHANDIGARH, INDIA',2244658909, 36,'adesai@ams.com', 'M','TRAFFIC MONITOR','Chandigarh International Airport',80000);

INSERT INTO TICKET(TICKET_SOURCE, TICKET_DESTINATION, TICKET_DATE_OF_BOOKING, TICKET_DATE_OF_CANCELLATION, TICKET_DATE_OF_TRAVEL, TICKET_SEAT_NO, TICKET_CLASS, TICKET_PRICE,ticket_passenger_id)
VALUES('BOM','DFW','11-MAY-21','12-MAY-21','15-DEC-21','32A','ECONOMY',1000,1);
INSERT INTO TICKET(TICKET_SOURCE, TICKET_DESTINATION, TICKET_DATE_OF_BOOKING, TICKET_DATE_OF_CANCELLATION, TICKET_DATE_OF_TRAVEL, TICKET_SEAT_NO, TICKET_CLASS, TICKET_PRICE,ticket_passenger_id)
VALUES('JFK','BOM','11-JUN-21','10-DEC-21','20-DEC-16','45D','ECONOMY',1200,2);
INSERT INTO TICKET(TICKET_SOURCE, TICKET_DESTINATION, TICKET_DATE_OF_BOOKING, TICKET_DATE_OF_CANCELLATION, TICKET_DATE_OF_TRAVEL, TICKET_SEAT_NO, TICKET_CLASS, TICKET_PRICE,ticket_passenger_id)
VALUES('IAH','DEL','21-AUG-21','','25-DEC-21','1A','BUSINESS',900,3);
INSERT INTO TICKET( TICKET_SOURCE, TICKET_DESTINATION, TICKET_DATE_OF_BOOKING, TICKET_DATE_OF_CANCELLATION, TICKET_DATE_OF_TRAVEL, TICKET_SEAT_NO, TICKET_CLASS, TICKET_PRICE,ticket_passenger_id)
VALUES('IXC','IAH','10-AUG-21','30-SEP-21','12-JAN-22','20C','FIRST-CLASS',1150,4);
INSERT INTO TICKET(TICKET_SOURCE, TICKET_DESTINATION, TICKET_DATE_OF_BOOKING, TICKET_DATE_OF_CANCELLATION, TICKET_DATE_OF_TRAVEL, TICKET_SEAT_NO, TICKET_CLASS, TICKET_PRICE,ticket_passenger_id)
VALUES('JFK','TPA','13-JUN-21','9-DEC-21','10-DEC-21','54E','ECONOMY',850,5);
INSERT INTO TICKET(TICKET_SOURCE, TICKET_DESTINATION, TICKET_DATE_OF_BOOKING, TICKET_DATE_OF_CANCELLATION, TICKET_DATE_OF_TRAVEL, TICKET_SEAT_NO, TICKET_CLASS, TICKET_PRICE,ticket_passenger_id)
VALUES('BOM','DFW','11-NOV-21','','12-FEB-22','43B','ECONOMY',975,6);
INSERT INTO TICKET(TICKET_SOURCE, TICKET_DESTINATION, TICKET_DATE_OF_BOOKING, TICKET_DATE_OF_CANCELLATION, TICKET_DATE_OF_TRAVEL, TICKET_SEAT_NO, TICKET_CLASS, TICKET_PRICE,ticket_passenger_id)
VALUES('IAH','DEL','15-NOV-21','1-DEC-21','25-DEC-21','27B','FIRST-CLASS',780,7);
INSERT INTO TICKET(TICKET_SOURCE, TICKET_DESTINATION, TICKET_DATE_OF_BOOKING, TICKET_DATE_OF_CANCELLATION, TICKET_DATE_OF_TRAVEL, TICKET_SEAT_NO, TICKET_CLASS, TICKET_PRICE,ticket_passenger_id)
VALUES('SFO','FRA','15-OCT-21','10-NOV-21','18-DEC-21','34E','ECONOMY',800,8);
INSERT INTO TICKET(TICKET_SOURCE, TICKET_DESTINATION, TICKET_DATE_OF_BOOKING, TICKET_DATE_OF_CANCELLATION, TICKET_DATE_OF_TRAVEL, TICKET_SEAT_NO, TICKET_CLASS, TICKET_PRICE,ticket_passenger_id)
VALUES('IXC','IAH','12-NOV-21','','30-DEC-21','54C','ECONOMY',1175,9);
INSERT INTO TICKET(TICKET_SOURCE, TICKET_DESTINATION, TICKET_DATE_OF_BOOKING, TICKET_DATE_OF_CANCELLATION, TICKET_DATE_OF_TRAVEL, TICKET_SEAT_NO, TICKET_CLASS, TICKET_PRICE,ticket_passenger_id)
VALUES('BOM','SFO','22-JAN-21','','15-DEC-21','38A','ECONOMY',1250,10);
INSERT INTO TICKET(TICKET_SOURCE, TICKET_DESTINATION, TICKET_DATE_OF_BOOKING, TICKET_DATE_OF_CANCELLATION, TICKET_DATE_OF_TRAVEL, TICKET_SEAT_NO, TICKET_CLASS, TICKET_PRICE,ticket_passenger_id)
VALUES('FRA','DEL','19-OCT-21','','31-DEC-21','57F','ECONOMY',650,11);
INSERT INTO TICKET(TICKET_SOURCE, TICKET_DESTINATION, TICKET_DATE_OF_BOOKING, TICKET_DATE_OF_CANCELLATION, TICKET_DATE_OF_TRAVEL, TICKET_SEAT_NO, TICKET_CLASS, TICKET_PRICE,ticket_passenger_id)
VALUES('IXC','IAH','20-NOV-21','','12-JAN-22','45D','ECONOMY',1000,12);
INSERT INTO TICKET(TICKET_SOURCE, TICKET_DESTINATION, TICKET_DATE_OF_BOOKING, TICKET_DATE_OF_CANCELLATION, TICKET_DATE_OF_TRAVEL, TICKET_SEAT_NO, TICKET_CLASS, TICKET_PRICE,ticket_passenger_id)
VALUES('BOM','DFW','13-MAY-21','25-MAY-21','15-DEC-21','37C','ECONOMY',1300,13);
INSERT INTO TICKET(TICKET_SOURCE, TICKET_DESTINATION, TICKET_DATE_OF_BOOKING, TICKET_DATE_OF_CANCELLATION, TICKET_DATE_OF_TRAVEL, TICKET_SEAT_NO, TICKET_CLASS, TICKET_PRICE,ticket_passenger_id)
VALUES('FRA','DEL','26-JUN-21','30-NOV-21','23-DEC-21','55C','ECONOMY',790,14);
INSERT INTO TICKET(TICKET_SOURCE, TICKET_DESTINATION, TICKET_DATE_OF_BOOKING, TICKET_DATE_OF_CANCELLATION, TICKET_DATE_OF_TRAVEL, TICKET_SEAT_NO, TICKET_CLASS, TICKET_PRICE,ticket_passenger_id)
VALUES('BOM','DFW','11-AUG-21','','22-DEC-21','33F','ECONOMY',999,15);

GO
-- Verify
select * from city
select * from airline
select * from airport
select * from flight
select * from passenger
select * from employee
select * from ticket

