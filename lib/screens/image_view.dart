import 'package:flutter/material.dart';

class ImageView extends StatelessWidget {
  static const routeName = '/image-view';
  @override
  Widget build(BuildContext context) {
    String url = ModalRoute.of(context).settings.arguments.toString();
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black38,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Center(
          //mainAxisAlignment: MainAxisAlignment.center,
          //children: <Widget>[
          child: Hero(
            tag: url,
            child: Image.network(
              url, fit: BoxFit.contain,
              //width: double.infinity,
              loadingBuilder: (BuildContext context, Widget child,
                  ImageChunkEvent loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes
                        : null,
                  ),
                );
              },
            ),
          ),
          //],
        ),
      ),
    );
  }
}
