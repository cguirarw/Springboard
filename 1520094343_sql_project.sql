/* Welcome to the SQL mini project. For this project, you will use
Springboard' online SQL platform, which you can log into through the
following link:

https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

Note that, if you need to, you can also download these tables locally.

In the mini project, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */



/* Q1: Some of the facilities charge a fee to members, but some do not.
Please list the names of the facilities that do. */
SELECT name FROM `Facilities` WHERE membercost > 0


/* Q2: How many facilities do not charge a fee to members? */
SELECT COUNT(name) FROM `Facilities` WHERE membercost = 0


/* Q3: How can you produce a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost?
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */
SELECT facid, name, membercost, monthlymaintenance FROM `Facilities` WHERE membercost < 0.2*monthlymaintenance


/* Q4: How can you retrieve the details of facilities with ID 1 and 5?
Write the query without using the OR operator. */
SELECT * FROM `Facilities` WHERE facid = 1 
UNION 
SELECT * FROM `Facilities` WHERE facid = 5

/* Q5: How can you produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100? Return the name and monthly maintenance of the facilities
in question. */
SELECT name, monthlymaintenance
CASE WHEN monthlymaintenance > 100 THEN 'expensive' ELSE 'cheap' END
FROM Facilities;


/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Do not use the LIMIT clause for your solution. */
SELECT firstname, surname, joindate FROM Members
WHERE joindate = (SELECT MAX(joindate) FROM Members);

/* Q7: How can you produce a list of all members who have used a tennis court?
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */
SELECT DISTINCT m.firstname || ' ' || m.surname AS member, f.name AS facility
FROM Members AS m
INNER JOIN Bookings AS b ON (m.memid = b.memid)
INNER JOIN Facilities AS f ON (b.facid = f.facid)
WHERE f.name LIKE 'Tennis%'
ORDER BY member, facility;

fullname = Member.firstname + ' ' + Member.surname
query = (Member
         .select(fullname.alias('member'), Facility.name.alias('facility'))
         .join(Booking)
         .join(Facility)
         .where(Facility.name.startswith('Tennis'))
         .order_by(fullname, Facility.name)
         .distinct())

/* Q8: How can you produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30? Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */
SELECT Members.firstname, Members.surname, Facilities.name,
case 
	when Members.memid = 0 then Bookings.slots * Facilities.guestcost
	else Bookings.slots * Facilities.membercost
end as cost
from cd.members 
	inner join cd.Fookings on Members.memid = Bookings.memid
	inner join cd.Facilities on Fookings.facid = Facilities.facid
where 
Bookings.starttime >= '2012-09-14' and Bookings.starttime < '2012-09-15' and (
(Members.memid = 0 and Bookings.slots*Facilities.guestcost >= 30 ) or 
(Members.memid != 0 and Bookings.slots*Facilities.membercost >= 30) )
order by cost desc;

/* Q9: This time, produce the same result as in Q8, but using a subquery. */
SELECT member, facility, cost from (
  SELECT
  m.firstname || ' ' || m.surname as member,
  f.name as facility,
  CASE WHEN m.memid = 0 THEN b.slots * f.guestcost
  ELSE b.slots * f.membercost END AS cost
  FROM Members AS m
  INNER JOIN Bookings AS b ON m.memid = b.memid
  INNER JOIN Facilities AS f ON b.facid = f.facid
  WHERE date_trunc('day', b.starttime) = '2012-09-14'
) as bookings
WHERE cost > 30
ORDER BY cost DESC;
cost = Case(Member.memid, (
    (0, Booking.slots * Facility.guestcost),
), (Booking.slots * Facility.membercost))

iq = (Member
      select(fullname.alias('member'), Facility.name.alias('facility'),
              cost.alias('cost'))
      join(Booking)
      join(Facility)
      where(fn.date_trunc('day', Booking.starttime) == datetime.date(2012, 9, 14)))

query = (Member
         select(iq.c.member, iq.c.facility, iq.c.cost)
         from_(iq)
         where(iq.c.cost > 30)
         order_by(SQL('cost').desc()))

for row in query.dicts():
    print(row['member'], row['facility'], row['cost'])


/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */
revenue = fn.SUM(Booking.slots * Case(None, (
    (Booking.member == 0, Facility.guestcost),
), Facility.membercost))

query = (Facility
         .select(Facility.name, revenue.alias('revenue'))
         .join(Booking)
         .group_by(Facility.name)
         .having(revenue < 1000)
         .order_by(SQL('revenue')))
