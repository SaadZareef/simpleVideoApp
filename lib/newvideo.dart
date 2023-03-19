import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:videoapp/playvideo.dart';

class VideoCRUD extends StatefulWidget {
  @override
  _VideoCRUDState createState() => _VideoCRUDState();
}

class _VideoCRUDState extends State<VideoCRUD> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late DatabaseReference videoRef;
  late String videoURL;
  Future singin() async {
    await FirebaseAuth.instance.signInAnonymously();
  }

  @override
  void initState() {
    super.initState();
    singin();
    videoRef = FirebaseDatabase.instance.reference().child("videos");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video CRUD"),
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                onSaved: (value) {
                  videoURL = value!;
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Please enter video URL";
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: "Video URL",
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    createVideo();
                  }
                },
                child: Text("Create"),
              ),
              SizedBox(height: 10),
              Expanded(
                child: StreamBuilder(
                  stream: videoRef.onValue,
                  builder: (context, snap) {
                    if (snap.hasData &&
                        !snap.hasError &&
                        snap.data!.snapshot.value != null) {
                      // Map data = snap.data!.snapshot.value;
                      var data = snap.data!.snapshot.value as Map;
                      List<Widget> videos = [];
                      data.forEach((key, value) {
                        videos.add(
                            // ListTile(
                            //   title: Text(value["videoURL"]),
                            //   leading: IconButton(
                            //     icon: Icon(Icons.video_call),
                            //     onPressed: () {
                            //       Navigator.of(context).push(MaterialPageRoute(
                            //         builder: (context) => VideoPlayerScreen(
                            //             videoURL: value["videoURL"]),
                            //       ));
                            //     },
                            //   ),
                            //   trailing: IconButton(
                            //     icon: Icon(Icons.delete),
                            //     onPressed: () {
                            //       deleteVideo(key);
                            //     },
                            //   ),
                            // ),
                            Card(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoPlayerScreen(
                                    // videoUrl:value["videoURL"],
                                    // coverImageUrl:value["videoURL"],
                                    videoURL: value["videoURL"],
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              children: <Widget>[
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  child: Image.network(
                                    value["coverURL"],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Video  ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ));
                      });
                      return ListView(
                        children: videos,
                      );
                    } else {
                      return Container(
                        child: Text("No Data"),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          XFile? video =
              await ImagePicker().pickVideo(source: ImageSource.gallery);
          File vid = File(video!.path);
          if (video != null) {
            // Upload the video to Firebase Storage
            String fileName = video.path.split("/").last;
            Reference storageReference =
                FirebaseStorage.instance.ref().child('videos/$fileName');
            UploadTask uploadTask = storageReference.putFile(vid);
            await uploadTask.whenComplete(() => null);
            String downloadUrl = await storageReference.getDownloadURL();
            final thumbnail = await VideoThumbnail.thumbnailData(
              video: vid.path,
              imageFormat: ImageFormat.JPEG,
              maxHeight: 512,
              maxWidth: 512,
              quality: 80,
            );
            final coverRef = FirebaseStorage.instance
                .ref()
                .child("covers/${vid.path.split("/").last}.jpeg");
            final coverTask = coverRef.putData(thumbnail!);
            await coverTask.whenComplete(() => null);
            String downloadUrlImage = await coverRef.getDownloadURL();

// Add the download URL to the Firebase Database
            FirebaseDatabase.instance
                .reference()
                .child('videos')
                .push()
                .set({'videoURL': downloadUrl, 'coverURL': downloadUrlImage});
          }
        },
        child: Icon(Icons.video_library),
      ),
      // bottomNavigationBar: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.of(context).push(MaterialPageRoute(
      //       builder: (context) => VideoPlayerScreen(videoURL: videoURL),
      //     ));
      //   },
      // ),
    );
  }

  void createVideo() {
    videoRef.push().set({
      "videoURL": videoURL,
    });
  }

  void deleteVideo(String videoId) {
    videoRef.child(videoId).remove().then((_) {
      print("Delete $videoId successful");
    });
  }
}
