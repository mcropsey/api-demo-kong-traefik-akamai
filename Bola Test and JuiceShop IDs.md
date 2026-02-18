
# uses jwt.io site to view tokens

# Clear Mac DNS Cache ##############
sudo dscacheutil -flushcache                                                                  ─╯
sudo killall -HUP mDNSResponder
# ##################################


# Begin BOLA Test
GET /rest/basket/1 HTTP/2
Host: juice.cropseyit.com
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdGF0dXMiOiJzdWNjZXNzIiwiZGF0YSI6eyJpZCI6MzYsInVzZXJuYW1lIjoiIiwiZW1haWwiOiJtaWtlQG15LmxhYiIsInBhc3N3b3JkIjoiMzMyZWU1ZTkwMzFjZWIyZmEyNWEyZmVlY2RkMzJmYzkiLCJyb2xlIjoiY3VzdG9tZXIiLCJkZWx1eGVUb2tlbiI6IiIsImxhc3RMb2dpbklwIjoiMC4wLjAuMCIsInByb2ZpbGVJbWFnZSI6Ii9hc3NldHMvcHVibGljL2ltYWdlcy91cGxvYWRzL2RlZmF1bHQuc3ZnIiwidG90cFNlY3JldCI6IiIsImlzQWN0aXZlIjp0cnVlLCJjcmVhdGVkQXQiOiIyMDI2LTAyLTE4IDEzOjU5OjU4LjAyMyArMDA6MDAiLCJ1cGRhdGVkQXQiOiIyMDI2LTAyLTE4IDEzOjU5OjU4LjAyMyArMDA6MDAiLCJkZWxldGVkQXQiOm51bGx9LCJpYXQiOjE3NzE0MjQ1Mjl9.JDE1ORMIMLqfqTuO4CwU2GV5b67UdrbcIXxZQ3eyep51K56eZplctFtgOypcRTBMh7QEwH0jkjYp3-AjU-eA8AJByS6VD5uZZpD9AFlspb6vOcD2PqLwSig-NfEvEOTpnX0Situz5ApYLZssh06GPGnvb8Lt6JBaZUFL5scRHFo
Content-Type: application/json
# End BOLA Test


# OWASP Juice Shop – Default User Accounts

## Admin Account
| Email              | Password  | Notes                      |
|--------------------|-----------|----------------------------|
| admin@juice-sh.op  | admin123  | Default built-in admin.    |

## Regular / Deluxe Users
| Email               | Password       | Notes                |
|---------------------|----------------|----------------------|
| jim@juice-sh.op     | ncc-1701       | Regular user         |
| bender@juice-sh.op  | OhGodPleaseNo  | Regular user         |
| tobi@juice-sh.op    | .forget        | Deluxe user          |
| wurstbrot@juice-sh.op | Wurstbrot    | Regular user         |
| bjoern@juice-sh.op  | bjoern         | Developer easter egg |

## Support / Team Users
| Email                 | Password       | Notes                          |
|-----------------------|----------------|--------------------------------|
| support@juice-sh.op   | any password   | Weak password rules (CTF test) |
| morty@juice-sh.op     | random         | Exists depending on seed       |

## Challenge-Specific Accounts
| Email                     | Password     | Purpose                        |
|---------------------------|--------------|--------------------------------|
| mc.safesearch@juice-sh.op | Mr. N00dles  | Privacy challenge              |
| amy@juice-sh.op           | K1ngK0ng     | Deluxe user                    |
| john@juice-sh.op          | varies       | Mass Assignment / BOLA demos   |

