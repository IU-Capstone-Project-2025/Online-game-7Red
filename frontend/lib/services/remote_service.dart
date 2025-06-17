import '../models/post.dart';
import 'package:http/http.dart' as http;

class RemoteService {
  Future<Post> getPost() async {
    final response = await http.get(
        Uri.parse('https://jsonplaceholder.typicode.com/posts/1'));
    if (response.statusCode == 200) {
      return postFromJson(response.body);
    } else {
      throw Exception('Failed to load post');
    }
  }

  sendPost(Post post) async {
    final response = await http.post(
        Uri.parse('https://jsonplaceholder.typicode.com/posts'),
        body: postToJson(post));
    // if (response.statusCode == 201) {
    //   return postFromJson(response.body);
    // } else {
    //   throw Exception('Failed to create post');
    // }
  }
}

getData() async {
  Post post = await RemoteService().getPost();
}

sendData() async {
  Post post = Post(message: 'Try to send data, 12345');
  await RemoteService().sendPost(post);
}

