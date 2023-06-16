
const express = require("express");
const app = express();
const mongoose = require("mongoose");
const bodyParser = require("body-parser");
const ejs = require('ejs');
const multer  =   require('multer');  
const fs = require('fs');
const alert = require('alert'); 
const path = require('path');
const datestring = Date();
const nodeMailer = require('nodemailer');
const uuidv4 = require("uuid");

app.set('view engine', 'pug');
app.use('/static', express.static(path.join(__dirname, 'uploads')))

app.get('/get-images', (req, res) => {
    let images = getImagesFromDir(path.join(__dirname, 'uploads'));
     res.render('index', { title: 'Node js – Auto Generate a Photo Gallery from a Directory', images: images })
});

// dirPath: target image directory
function getImagesFromDir(dirPath) {

    // All iamges holder, defalut value is empty
    let allImages = [];

    // Iterator over the directory
    let files = fs.readdirSync(dirPath);

    // Iterator over the files and push jpg and png images to allImages array.
    for (file of files) {
        let fileLocation = path.join(dirPath, file);
        var stat = fs.statSync(fileLocation);
        if (stat && stat.isDirectory()) {
            getImagesFromDir(fileLocation); // process sub directories
        } else if (stat && stat.isFile() && ['.jpg', '.png'].indexOf(path.extname(fileLocation)) != -1) {
            allImages.push('static/'+file); // push all .jpf and .png files to all images 
        }
    }

    // return all images in array formate
    return allImages;
}


app.set('view engine', 'ejs');

const storage =   multer.diskStorage({  
	destination: function (req, file, callback) {  
	  callback(null, './uploads');  
	},  
	filename: function (req, file, callback) {  
	  callback(null, file.originalname);  
	}  
  });

const upload = multer({ storage : storage}).single('myfile');

app.post('/uploadjavatpoint',function(req,res){  
    upload(req,res,function(err) {  
        var file_path=req.file.path;
        console.log(file_path);
        console.log(adhaarno);
        kycconn.findOneAndUpdate({adhaarno:adhaarno} ,{ filename2: file_path },
                            function (err, docs) {
    if (err){
        console.log(err)
    }
    else{
        console.log("Updated status : ", docs);
    }
});
        if(err) {  
            return res.end("Error uploading file.");  
        }  
        res.redirect('/photoupload');;  
    });  
});  

app.post('/uploadjavatpointphoto',function(req,res){   
    upload(req,res,function(err) {  
        var file_path=req.file.path;
        console.log(file_path);
        console.log(adhaarno);
        kycconn.findOneAndUpdate({adhaarno:adhaarno} ,{ filename1: file_path },
                            function (err, docs) {
    if (err){
        console.log(err)
    }
    else{
        console.log("Updated status : ", docs);
    }
});


        if(err) {  
            return res.end("Error uploading file.");  
        }  
        res.redirect('/success');;  
    });  
});


app.use(bodyParser.urlencoded({extended: true}));

app.use(express.static(__dirname + '/'));

mongoose.connect('mongodb://127.0.0.1:27017/kyc', {useNewUrlParser: true});
var conn = mongoose.connection;

const kyceschema = {
    first_name: String,
	last_name: String,
	birthday: String,
	gender: String,
	email: String,
	phone: String,
    filename1: String,
    filename2: String,
	status: String,
	adhaarno: String,
	panno: String,
    user:String,
    login:String,
    date:String,
    count:String,
    rcount:String,
    amount:String,
    date:String,
    key:String,
    donation:String,
    rstatus:String,
    private:String,
    user:String,
    volunter:String,
    beneficiary:String,
    joined:String,
    closed:String,
    deleted:String,
    active:String,
    volnum:integer,
    volreq:integer,
    vulunterlist:array

}

const kycconn = mongoose.model("kycdb", kyceschema)

app.get("/", function(req, res) {

    res.sendFile(__dirname + "/kycupload.html");
    // res.sendFile('./index.html', {root: _dirname});
})



app.post("/reject", function(req, res){

    var _id = req.body.id;
    console.log(_id); 
    kycconn.findByIdAndUpdate(_id, { status: 'Rejected' },
                            function (err, docs) {
    if (err){
        console.log(err)
    }
    else{
        console.log("Updated status : ", docs);
    }
});
    res.redirect('/kyc');
})

app.post("/approve", function(req, res){

    var _id = req.body.id;
    console.log(_id); 
    kycconn.findByIdAndUpdate(_id, { status: 'Active' },
                            function (err, docs) {
    if (err){
        console.log(err)
    }
    else{
        console.log("Updated status : ", docs);
    }
});
    res.redirect('/kyc');
})


app.post("/update", function(req, res){

    var _id = req.body.id;
    console.log(_id); 

    kycconn.findByIdAndUpdate(_id, { status: 'Joined' },
                            function (err, docs) {
    if (err){
        console.log(err)
    }
    else{
        console.log("Updated status : ", docs);
    }
});
    res.redirect('/vlistuser');
})


app.post("/accept", function(req, res){

    var _id = req.body.id;
    console.log(_id); 
    kycconn.findByIdAndUpdate(_id, { status: 'Accepted' },
                            function (err, docs) {
    if (err){
        console.log(err)
    }
    else{
        console.log("Updated status : ", docs);
    }
});
    res.redirect('/kyc');
})



app.get("/fileupload", function(req, res) {

    res.sendFile(__dirname + "/fileuploads.html");
    // res.sendFile('./booking.html', {root: _dirname});
})


app.get("/document", function(req, res) {

    res.sendFile(__dirname + "/documents.html");
    // res.sendFile('./booking.html', {root: _dirname});
})


app.get("/photoupload", function(req, res) {

    res.sendFile(__dirname + "/photoupload.html");
    // res.sendFile('./booking.html', {root: _dirname});
})

app.get("/success", function(req, res) {

    res.sendFile(__dirname + "/success.html");
    // res.sendFile('./booking.html', {root: _dirname});
})


app.get("/kyc", function(req, res) {
    kycconn.find({ "status": ["new" ,"Active"]}, function(err, kycs){
        res.render('kyclist', {
            kyclist: kycs

        })
        
    })
   
})

app.get("/newcharity", function(req, res) {
    kycconn.find({ "status": ["Active"]}, function(err, kycs){
        res.render('newcharity', {
            newcharity: kycs

        })
        
    })
   
})

app.get("/newcharitylist", function(req, res) {
    kycconn.find({ "status": ["Active","new"]}, function(err, kycs){
        res.render('newcharity', {
            newcharity: kycs

        })
        
    })
   
})

app.get("/vlist", function(req, res) {
    kycconn.find({ "status": ["volun","Joined","Not Joined"]}, function(err, kycs){
        res.render('vlist', {
            vlist: kycs

        })
        
    })
   
})


app.get("/blist", function(req, res) {
    kycconn.find({ "status": ["Active","new"]}, function(err, kycs){
        res.render('blist', {
            blist: kycs

        })
        
    })
   
})




app.get("/vlistuser", function(req, res) {
    kycconn.find({ "status": ["volun","Joined","Not Joined"]}, function(err, kycs){
        res.render('vlistuser', {
            vlistuser: kycs

        })
        
    })
   
})

app.post("/candcert", function(req, res){
    global.user = req.body.username;
    var username = req.body.username;
    console.log(username); 
    kycconn.updateMany({query: { user: req.body.username },
    update: { $inc: { login: "Yes" } }},
                            function (err, docs) {
    if (err){
        console.log(err) 
    }
    else{
        console.log("Updated status : ", docs);
    }
});
    res.redirect('/cand');
})

app.get("/cand", function(req, res) {
    kycconn.find({ "user":user}, function(err, kycs){
        res.render('candidatelist', {
            kyclist: kycs

        })
        
    })
   
})






app.post("/", function(req, res){
    global.first_name = req.body.first_name;
    kycconn.countDocuments({"first_name": req.body.first_name}, function (err, count){ 
        if(count>0){
            alert("Same Charity Exist");
        }
        else{
            let newNote = new kycconn({
                first_name: req.body.first_name,
                last_name: req.body.last_name,
                birthday: req.body.birthday,
                status: 'Pending'
                    
            });
            newNote.save();
        
            res.redirect('http://localhost:3005/kyc');
        }

    });



})

const kycconndon = mongoose.model("dondb", kyceschema)



app.post("/adddonation", function(req, res){
    global.user = req.body.user;
    kycconn.countDocuments({"user": req.body.user}, function (err, count){ 
        if(count>0){
            alert("User already have a  Donation Rrequest");
        }
        else{
            let newNote = new kycconn({
                user: req.body.user,
                amount: req.body.amount,
                date: req.body.reqDate,
                date: req.body.donation,
                rstatus: 'requested',
                status: 'requested'
                    
            });
            newNote.save();
        
            res.redirect('http://localhost:3005/donationslist');
        }

    });



})



app.get("/donationslist", function(req, res) {
    kycconn.find({ "rstatus": ["requested","Active"]}, function(err, kycs){
        res.render('donationslist', {
            donationslist: kycs

        })
        
    })
   
})

app.post("/vadd", function(req, res){
    global.first_name = req.body.first_name;
    kycconn.countDocuments({"first_name": req.body.first_name}, function (err, count){ 
        if(count>0){
            alert("Same Charity Exist");
        }
        else{
            let newNote = new kycconn({
                first_name: req.body.first_name,
                date: req.body.reqDate,
                birthday: req.body.birthday,
                status: 'volun',
                email: req.body.email,
                status:'Not Joined',
                count:req.body.count,
                rcount:'0'
                    
            });
            newNote.save();
        
            res.redirect('http://localhost:3005/vlist');
        }

    });
})
    app.post("/badd", function(req, res){
        global.first_name = req.body.first_name;
        kycconn.countDocuments({"first_name": req.body.first_name}, function (err, count){ 
            if(count>0){
                alert("Same Charity Exist");
            }
            else{
                let newNote = new kycconn({
                    first_name: req.body.first_name,
                    date: req.body.reqDate,
                    status: 'new',
                    bstatus: 'Waiting',
                    count:req.body.count
                        
                });
                newNote.save();
            
                res.redirect('http://localhost:3005/blist');
            }
    
        });  


})

function getRandomInt(max) {
    return Math.floor(Math.random() * max);
  }
app.post("/savedonate", function(req, res){
    global.user = req.body.user;
    global.key = getRandomInt(500000);
    kycconn.countDocuments({"user": req.body.user}, function (err, count){ 
        if(count>100){
            alert("Duplicate");
        }
        
        else{
            let newNote = new kycconn({
                user: req.body.user,
                email: req.body.email,
                amount: req.body.amount,
                first_name: req.body.time,
                status:'Donated',
                private:req.body.agree,
                key:key
                    
            });
            newNote.save();
        
            res.redirect('http://localhost:3005/donated');
        }

    });


})



app.get("/donated", function(req, res) {
    kycconn.find({ "key": key}, function(err, kycs){
        res.render('donated', {
            donated: kycs

        })
        
    })
   
})


app.get("/featured", function(req, res) {
    kycconn.find({  "status": ["Donated"],"private": ["agree"]}, function(err, kycs){
        res.render('featured', {
            featured: kycs

        })
        
    }).limit(5)
   
})





app.listen(3005, function() {
    console.log("Server is up on 3005")
})
