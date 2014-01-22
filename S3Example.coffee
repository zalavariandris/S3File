
Meteor._fileDep = new Deps.Dependency
if Meteor.isClient

    Session.set('fileUploaded', false)
    Session.set('uploadedKey', false)
    Session.set('uploadedURL', "")

    Template.S3FileUploader.events
        'change [type=file]': (event, template)->
            fileRef = template.find('[type=file]').files[0]

            s3File = new S3File
                key: fileRef.name,
                bucket: "myportfoliositebucket",
                endpoint: "s3-eu-west-1.amazonaws.com"
                
            Session.set('uploadedKey', fileRef.name)
            Session.set('uploadedURL', s3File.getURL())
            s3File.upload fileRef

            progressBar = template.find('progress')

            s3File.onprogress = (xhrEvent)->
                progressBar.value = xhrEvent.loaded / xhrEvent.total * 100

            s3File.onload = (xhrEvent)->
                console.log 'uploaded'
                Session.set('fileUploaded', true)

        'click [name=delete]': (event, template)->
            s3File = new S3File
                key: Session.get('uploadedKey'),
                bucket: "myportfoliositebucket",
                endpoint: "s3-eu-west-1.amazonaws.com"

            s3File.delete()

            Session.set('fileUploaded', false)

    
    Template.S3FileUploader.helpers
        uploaded: ->
            Session.get('fileUploaded')

        key: ->
            Session.get('uploadedKey')
        url: ->
            Session.get('uploadedURL')


if Meteor.isServer
    Meteor.startup ->
        console.log 'server startup'

