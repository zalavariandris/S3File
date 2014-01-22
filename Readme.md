Very Simple file uploading to S3
================================


usage
-----
signString method uses environment variables
AWS_ACCESS_KEY_ID
AWS_SECRET_KEY


* to upload a file

fileRef = $("input[type=file]")[0].files[0]

s3file = new S3File
    endpoint: "s3endpoint", 
    bucket: "YOUR BUCKET",
    key: fileRef.name

fileURL = s3file.getURL

s3file.upload fileRef

s3file.onprogress = (xhrEvent)->
    console.log "progess: " + xhrEvent.total / xhrEvent.loaded + "%"

s3File.onload = (xhrEvent)->
    # file uploaded

* to delete a file
s3file = new S#File
    endpoint: "s3endpoint", 
    bucket: "YOUR BUCKET",
    key: fileRef.name

s3file.delete()

s3file.onload = (xhrEvent)->
    #file deleted


