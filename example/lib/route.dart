import 'home.dart';

import 'package:flutter/widgets.dart';

class SectionViewRoute {
  static const String initialRoute = "/";
  static final Map<String, WidgetBuilder> routes = {
    "/": (context) => Stack(
          children: const [
            HomePage(
              title: "Home",
            ),
          ],
        ),
    // "/CountryList": (context) => const CountryList(),
  };
}
