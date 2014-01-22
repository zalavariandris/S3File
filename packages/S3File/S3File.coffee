

class Reactive
    @keys = []
    constructor: ->
        # setup properties to hold field values, and dependencies
        @_fields = {}
        @_deps = {}

        # define setters end getters for reactive keys
        properties = {}
        for key in @constructor.keys
            do (key) =>

                access = {
                    get: ->
                        #console.log "get '"+field+"'"
                        @_get( key )
                    set: (value)->
                        #console.log "set '"+field+"' to:", value
                        @_set value, key
                        
                }
                properties[ key ] = access
                @_deps[key] = new Deps.Dependency

        Object.defineProperties @, properties

    _get: (key)->
        @_deps[key].depend()
        return @_fields[key]

    _set: (value, key)->
        #console.log 'set value:  forKey:', value, key
        @_fields[key] = value
        @_deps[key].changed()


class S3File # extends Reactive
    # @keys = [
    #     'uploading', 'uploadProgress', 'uploaded',
    #     'deleted',
    #     'endpoint', 'bucket',
    #     'fileRef'
    # ]

    constructor: (options)->
        # super()

        # this.uploading      = options?.uploading      or false
        # this.uploadProgress = options?.uploadProgress or 0
        # this.uploaded       = options?.uploaded       or false
        # this.deleted        = options?.deleted        or false
        
        this.endpoint       = options?.endpoint       or ""
        this.bucket         = options?.bucket         or ""
        this.key            = options?.key            or ""

    getURL: ->
        return "https://"+@endpoint+"/"+@bucket+"/"+@key


    upload: (fileRef)->
        ###
        create policy string
        ###
        duration = 10 * 60 *1000 #milliseconds
        currentDate = new Date
        dateExpired = new Date( currentDate.getTime() + duration )
        policy = 
            "expiration":dateExpired.toISOString()
            "conditions":[
                {"bucket": @bucket},
                ["eq", "$key", @key],
                { "acl":"public-read" },
                #["content-length-range", 0, filesize * 1000000],
                ["starts-with", "$Content-Type", ""]
            ]

        try
            StringToSign = btoa JSON.stringify policy # convert policy to base46String
        catch error
            callback.call this, error, undefined, undefined
            return

        ###
        signString
        ###
        Meteor.call 'S3-signString', StringToSign, (error, Credentials)=>
            ###
            generateForm
            ###
            formData = new FormData
            #signing in ... is this the request header, and the rest is the body?
            formData.append 'AWSAccessKeyId', Credentials.accesskey
            formData.append 'signature', Credentials.signature
            #policy
            formData.append 'policy', btoa JSON.stringify policy
            #file
            formData.append 'key', @key
            formData.append 'acl', 'public-read'
            formData.append 'Content-Type', fileRef.type
            formData.append 'file', fileRef

            ###
            sendRequest
            ###
            xhr = new XMLHttpRequest
            xhr.upload.addEventListener 'progress', (xhrEvent)=>
                @onprogress.call this, xhrEvent
                # console.log 'upload progress'
                # percent = xhrEvent.loaded / xhrEvent.total
                # @uploadProgress = percent

            xhr.addEventListener 'load', (xhrEvent)=>
                @onload.call this, xhrEvent
                # if xhrEvent.target.status == 204 #No Content
                #     @uploading = false
                #     @uploaded = true
                #     @uploadProgress = 0
                # else if xhrEvent.target.status >= 400 #error
                #     errorCode = xhrEvent.target.status
                #     reason = xhrEvent.target.statusText
                #     xml = xhrEvent.target.responseXML
                #     details = xhrEvent.responseText
                #     error = new Meteor.Error errorCode, reason, details
                #     callback.call this, error, undefined, 0
                # else
                #     console.warn "xhr loaded, de nem reagáltunk rá !!!"


            xhr.addEventListener 'error', (xhrEvent)=>
                @onerror.call this, xhrEvent
                #console.error 'error occured', xhrEvent

            xhr.addEventListener 'abort', (xhrEvent)=>
                @onabort.call this, xhrEvent
                #console.log 'aborted', xhrEvent

            #send request
            #@uploading = true
            xhr.open 'POST', 'https://' + @bucket + '.' + @endpoint + "/", true
            xhr.send formData

    delete: ->
        ###
        error handling
        ###
        unless @key then throw new Meteor.Error 'key must be defined to delete'

        date = new Date
        dateString = date.toGMTString()+" +0000"
        StringToSign = "DELETE\n\n\n\n"+"x-amz-date:"+dateString+"\n"+"/"+@bucket+"/"+@key
        
        #sign string
        Meteor.call 'S3-signString', StringToSign, (error, Credentials)=>
            #Signature = @signString StringToSign
            Authorization = "AWS"+" "+Credentials.accesskey+":"+Credentials.signature

            #create request
            xhr = new XMLHttpRequest
            xhr.upload.addEventListener 'progress', (xhrEvent)->
                console.log 'progress...', xhrEvent

            xhr.addEventListener 'load', (xhrEvent)->
                console.log 'load', xhrEvent

            xhr.addEventListener 'error', (xhrEvent)->
                console.log 'error occured', xhrEvent
            xhr.addEventListener 'abort', (xhrEvent)->
                console.log 'aborted', xhrEvent

            xhr.open 'DELETE', 'https://' + @bucket + '.' + @endpoint + "/"+@key, true
            xhr.setRequestHeader 'Authorization', Authorization
            xhr.setRequestHeader 'x-amz-date', dateString
            xhr.send()

if Meteor.isServer
    Meteor.methods
        'S3-signString':(StringToSign)->
            # get acces keys from environment variables
            ACCESSKEY = process.env.AWS_ACCESS_KEY_ID
            SECRETKEY = process.env.AWS_SECRET_KEY

            #error handling
            unless ACCESSKEY then throw new Meteor.Error 'please set AWS_ACCESS_KEY_ID environment variable'
            unless SECRETKEY then throw new Meteor.Error 'please set AWS_SECRET_KEY environment variable'

            #utf8 string encoding
            encode_utf8 = (s)->
              return unescape(encodeURIComponent(s));

            #get require crypto
            crypto = Npm.require 'crypto'

            #generate signature with crypto
            signature = crypto.createHmac('sha1', SECRETKEY).update( StringToSign )
            signature = signature.digest('base64')

            #return Credentials
            return {signature: signature, accesskey: ACCESSKEY}




