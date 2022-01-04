<H1>QR2Pass</H1>


This is a proof of concept for an alternative (passwordless) authentication system to a web server. The authentication is based on public key cryptographic challenges, that can correctly responded only by the owner of the private key. Challenges are presented in the form of a QR code which are scanned by the mobile app.   


  
The project is based on the procedure proposed by the [Snap2Pass](https://mobisocial.stanford.edu/papers/soups10j.pdf) paper, but not on the corresponding [implementation](https://github.com/Mobisocial/Snap2Pass).
In contrast to Snap2Pass, it offers only public key authentication (i.e no shared secret) and there is no OpenID integration.



The server is written in Django and the  client (mobile app) is written in Swift for the iOS platform

You can check an online version of the server [here](https://qr2pass.herokuapp.com/)


# Overview


During registration, user provides their public key to the server.
For authentication, server presents a challenge (unique nonce that expires after 60 seconds). User needs to sign the challenge with their private key part. Server verifies the signature and if it's valid, user is authenticated into the web site.

The web app consists of 2 parts: 
- the **core** app that handles the web view (what users sees in their browser)
- the **api** app that handles the out-of-band communication (to/from the mobile app)




# Protocol overview

To complete the registration request, or to initate a login process, the web app (core) constructs QR codes that are scanned by the mobile app

## register QR


the registration QR has the following info:


 ```json
    {
        "version": Int, 
        "email": String, 
        "nonce": String,
        "provider": URL, 
        "respond_to": URL,
        "action": action enum //action.register 
    }
```

- version: version of the prorocol (currently ignored)
- email: the email provided in the registration form. It is currently used as a user identifier
- nonce: a unique nonce (used to avoid replay attacks)
- provider: base url for the site (this is the identifier for the site)
- respond_to: where the client should send its response
- action: either login or register (register in this case, duh!)

## login QR

the login QR has a very similar schema:

```json
    {
        "version": Int,
        "challenge": String,
        "validTill": Date, 
        "provider": URL, 
        "respond_to": URL,
        "action": action.login //action.login 
    }
```

email, is not provided by the server, but in the client's request (from the mobile app)


## Out of band requests/responses
*We define as out-of-band the requests between the mobile app and the server (api part)
Browser - server (core part) is in-band*


### Registration 

A user needs first to head to the registration page (in their browser) where they are asked for their email. 
If the email is valid and not already used, a registration QR code is presented (for 60 seconds).
The user uses the mobile app to scan the QR code.  
The app decodes the QR code (see [register schema](#register-qr) above) and extracts the URL from the "respond_to field"  
If there is no registration data in the app for this site (defined by the *"provider"* field), it will then send a register request to this URL using the following schema:


```json
    {
        "version": Int,
        "email": String,
        "public_key": String, 
        "nonce": String 
    }
```


- version: version of the prorocol (currently ignored)
- email: the user's email 
- public_key: the user's public key
- nonce: the nonce offered by the server


Upon receiving the request, the server will perform the following checks:

- request has the valid schema
- the nonce received is a valid one and has not expired.
- the nonce received, corresponds to the specific user.

If the checks are succesful, server creates a user in its DB and redirects the browser to login page

Server responds using the following schema (out-of-band):

```json
    {
        "version": Int,
        "email": String,
        "status": String, 
        "response_text": String 
    }
```

- status: "ok"/"nok"
- response_text: a message showing more info about the status (e.g "invalid token")


## Loging in

A previously registered user can head to the login page to log in.
A QR is presented (for 60 seconds)
The user uses the mobile app to scan the QR code.  
The app decodes the QR code (see [login schema](#login-qr) above) and extracts the URL from the "respond_to field".   
If there is registration data in the app for this site (defined by the *"provider"* field), it will then send a  register request to this URL using the following schema:


```json
{

    "version": Int,
    "username": String,
    "challenge": String, 
    "response": String 

}
```


 - username: the email of the user
 - challenge: the nonce provided by the server
 - response: the nonce signed by the private key of the user



Similarly to registration process, server will make some initial checks on the request (valid schema and nonce, etc). If the intial checks succeed, the signed challenge will be checked against the public key of the user (stored during the registration process). 
If all checks are succesful, user is authenticated in the backend and the browser will be redirected to the user page. 

Server responds to the app with a repsonse using the same response schema as the in the registration process 


# Running the project

## Client

The ios app doesn't use any external libraries and it is compatible to ios > 12.4   
Keep in mind that iOS won't accept initiating unsecure connections (plain HTTP). See [here](https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity) for more information and ways to circumvent that, in case you want to test this locally.    
Alternatively, you can use [ngrok](https://ngrok.com) to map an external https endpoint to your local machine 


## Server

### pre-requisites

The server uses redis for Django channels backend and for temporary storage (nonces), so you need to have redis running locally or remotely.   
It also uses [daphne](https://pypi.org/project/daphne/) as an asynchronous server. 
You can invoke daphne by running: 
```
daphne qr2pass.asgi:application --port <PORT> --bind 0.0.0.0 -v2
```

but locally you can also use the usual runserver command:

```
python manage.py runserver
```

### requirements

- create a virtual environment
- activate it
- pip3 install -r requirements.txt

### Settings
The default settings are defined in the settings/defaults.py file.   
You need to fill in some additional settings corresponding to your deployment environment (see deployment-template.py) and define the DJANGO_SETTINGS_MODULE environmental variable  for details) to point to your settings (see [here](https://docs.djangoproject.com/en/4.0/topics/settings/#designating-the-settings))




        