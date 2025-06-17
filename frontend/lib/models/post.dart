// To parse this JSON data, do
//
//     final post = postFromJson(jsonString);

import 'dart:convert';

Post postFromJson(String str) => Post.fromJson(json.decode(str));

String postToJson(Post data) => json.encode(data.toJson());

class Post {
    String message;

    Post({
        required this.message,
    });

    factory Post.fromJson(Map<String, dynamic> json) => Post(
        message: json["message"],
    );

    Map<String, dynamic> toJson() => {
        "message": message,
    };
}
