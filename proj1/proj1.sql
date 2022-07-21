-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people 
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people 
  WHERE namefirst LIKE '% %'
  ORDER BY namefirst, namelast
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), count(*)
  FROM people
  GROUP BY birthyear
  ORDER BY birthyear
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), count(*)
  FROM people
  GROUP BY birthyear
  HAVING AVG(height) > 70
  ORDER BY birthyear
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT p.namefirst AS namefirst, p.namelast AS namelast, p.playerid AS playerid, h.yearid AS yearid
  FROM people AS p INNER JOIN halloffame AS h
  ON p.playerid = h.playerid
  WHERE h.inducted = 'Y'
  ORDER BY h.yearid DESC, p.playerid
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT p.namefirst AS namefirst, p.namelast AS namelast, p.playerid AS playerid, s.schoolid AS schoolid, h.yearid AS yearid
  FROM people AS p, halloffame AS h, schools AS s, collegeplaying as c
  WHERE p.playerid = h.playerid AND p.playerid = c.playerid AND c.schoolid = s.schoolid AND h.inducted = 'Y' AND s.schoolState = 'CA'
  ORDER BY h.yearid DESC, s.schoolid, p.playerid
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT p.playerid AS playerid, p.namefirst AS namefirst, p.namelast AS namelast, c.schoolid AS schoolid
  FROM halloffame AS h LEFT OUTER JOIN collegeplaying AS c ON h.playerid = c.playerid
  INNER JOIN people AS p ON h.playerid = p.playerid 
  WHERE h.inducted = 'Y'
  ORDER BY p.playerid DESC, c.schoolid
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT p.playerid AS playerid, p.namefirst AS namefirst, p.namelast AS namelast, b.yearid AS yearid, ((b.H + b.H2B + (2 * b.H3B) + (3 * b.HR) + 0.0) / b.AB) AS slg
  FROM people AS p INNER JOIN batting AS b ON p.playerid = b.playerid
  WHERE b.AB > 50
  ORDER BY slg DESC, b.yearid, p.playerid
  LIMIT 10
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  SELECT p.playerid AS playerid, p.namefirst AS namefirst, p.namelast AS namelast, ((SUM(b.H) + SUM(b.H2B) + (2 * SUM(b.H3B)) + (3 * SUM(b.HR)) + 0.0) / SUM(b.AB)) AS lslg
  FROM people AS p INNER JOIN batting AS b ON p.playerid = b.playerid
  GROUP BY b.playerid
  HAVING SUM(AB) > 50
  ORDER BY lslg DESC, p.playerid
  LIMIT 10
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  SELECT p.namefirst AS namefirst, p.namelast AS namelast, ((SUM(b.H) + SUM(b.H2B) + (2 * SUM(b.H3B)) + (3 * SUM(b.HR)) + 0.0) / SUM(b.AB)) AS lslg
  FROM people AS p INNER JOIN batting AS b ON p.playerid = b.playerid
  GROUP BY b.playerid
  HAVING SUM(AB) > 50 AND lslg > (SELECT ((SUM(b.H) + SUM(b.H2B) + (2 * SUM(b.H3B)) + (3 * SUM(b.HR)) + 0.0) / SUM(b.AB))
    FROM people AS p INNER JOIN batting AS b ON p.playerid = b.playerid
    WHERE b.playerid = 'mayswi01')
  ORDER BY lslg DESC, p.playerid
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearid, MIN(salary), MAX(salary), AVG(salary)
  FROM salaries
  GROUP BY yearid
  ORDER BY yearid
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
  SELECT binid, ((SELECT max FROM q4i WHERE yearid = 2016) - (SELECT min FROM q4i WHERE yearid = 2016)) * binid * 0.1 + (SELECT min FROM q4i WHERE yearid = 2016) as low, 
  ((SELECT max FROM q4i WHERE yearid = 2016) - (SELECT min FROM q4i WHERE yearid = 2016)) * (binid + 1) * 0.1 + (SELECT min FROM q4i WHERE yearid = 2016) as high, 
  (SELECT COUNT(*) FROM salaries WHERE yearid = 2016 AND salary >= ((SELECT max FROM q4i WHERE yearid = 2016) - (SELECT min FROM q4i WHERE yearid = 2016)) * binid * 0.1 + (SELECT min FROM q4i WHERE yearid = 2016)
   AND ((binid < 9 AND salary < ((SELECT max FROM q4i WHERE yearid = 2016) - (SELECT min FROM q4i WHERE yearid = 2016)) * (binid + 1) * 0.1 + (SELECT min FROM q4i WHERE yearid = 2016)) 
   OR (binid = 9 AND salary <= ((SELECT max FROM q4i WHERE yearid = 2016) - (SELECT min FROM q4i WHERE yearid = 2016)) * (binid + 1) * 0.1 + (SELECT min FROM q4i WHERE yearid = 2016))))
  FROM binids
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  SELECT yearid, (SELECT MIN(salary) FROM salaries WHERE salaries.yearid = q4i.yearid) - (SELECT MIN(salary) FROM salaries WHERE salaries.yearid = q4i.yearid-1), (SELECT MAX(salary) FROM salaries WHERE salaries.yearid = q4i.yearid) - (SELECT MAX(salary) FROM salaries WHERE salaries.yearid = q4i.yearid-1), (SELECT AVG(salary) FROM salaries WHERE salaries.yearid = q4i.yearid)-(SELECT AVG(salary) FROM salaries WHERE salaries.yearid = q4i.yearid-1)
  FROM q4i
  WHERE yearid != 1985
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  SELECT p.playerid, p.namefirst, p.namelast, s.salary, s.yearid
  FROM people AS p INNER JOIN salaries AS s
  ON p.playerid = s.playerid
  WHERE (s.yearid = 2000 AND s.salary >= (
    SELECT MAX(salary)
    FROM salaries
    WHERE yearid = 2000
  )) OR (s.yearid = 2001 AND s.salary >= (
    SELECT MAX(salary)
    FROM salaries
    WHERE yearid = 2001
  ))
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT a.teamid, MAX(salary) - MIN(salary)
  FROM allstarfull AS a INNER JOIN salaries AS s
  ON a.playerid = s.playerid AND a.yearid = s.yearid AND a.teamid = s.teamid
  WHERE a.yearid = 2016
  GROUP BY a.teamid
;

