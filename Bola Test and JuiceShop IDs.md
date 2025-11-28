
# uses jwt.io site to view tokens

# Clear Mac DNS Cache ##############
sudo dscacheutil -flushcache                                                                  ─╯
sudo killall -HUP mDNSResponder
# ##################################


# Begin BOLA Test
GET /rest/basket/1 HTTP/2
Host: juice.corp.local
Authorization: Bearer <TOKEN HERE>
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

