import 'package:flutter/foundation.dart';

import 'supa.dart';

/// Ci sono modifiche all'aspetto del sito non ancora pubblicate?
/// (fa comparire il pallino sulla scheda Anteprima)
final draftChanged = ValueNotifier<bool>(false);

/// Aumenta ad ogni salvataggio: l'anteprima si ricarica da sola.
final draftRevision = ValueNotifier<int>(0);

Future<void> refreshDraftStatus() async {
  try {
    draftChanged.value = await supa.rpc('draft_status') == true;
  } catch (_) {
    // senza rete il pallino resta com'era
  }
}

/// Da chiamare dopo ogni salvataggio di sezioni, stile, nome o contatti.
void notifyDraftSaved() {
  draftRevision.value++;
  refreshDraftStatus();
}
