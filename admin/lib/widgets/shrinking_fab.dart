import 'package:flutter/material.dart';

/// Il pulsante "Nuovo …" mostra la scritta quando la lista è in cima e
/// diventa solo l'icona mentre si scorre, così non copre le righe.
mixin ShrinkingFab<T extends StatefulWidget> on State<T> {
  bool fabExtended = true;

  /// Da passare a un NotificationListener<ScrollNotification> attorno alla lista.
  bool onScrollForFab(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false; // i filtri scorrono di lato
    final extended = n.metrics.pixels < 24;
    if (extended != fabExtended) setState(() => fabExtended = extended);
    return false;
  }
}
