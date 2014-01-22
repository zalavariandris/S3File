Package.describe({
    summary: "S3File with FileReader like interface"
});

Package.on_use(function (api) {
    //AmazonS3
    api.use("coffeescript",['client','server']);
    api.add_files(["S3File.coffee"], ["client", "server"]);

    //register S3
    api.export(["S3File"], ["client", "server"]); // added export
});