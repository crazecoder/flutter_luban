
import 'package:example/app/io_app.dart';
import 'package:example/app/web_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() => runApp(kIsWeb ? WebApp() : IoApp());
