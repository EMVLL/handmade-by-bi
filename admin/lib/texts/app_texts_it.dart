import 'package:flutter/widgets.dart';

import 'app_texts.dart';

/// Testi in italiano.
class AppTextsIt implements AppTexts {
  @override
  Locale get locale => const Locale('it');

  // ---------------------------------------------------------------- generali
  @override
  String get appName => 'Handmade by Bi';
  @override
  String get retry => 'Riprova';
  @override
  String get cancel => 'Annulla';
  @override
  String get save => 'Salva';
  @override
  String get delete => 'Elimina';
  @override
  String get signOut => 'Esci';
  @override
  String get checkFields => 'Controlla i campi evidenziati in rosso';
  @override
  String maxChars(int max) => 'Massimo $max caratteri';

  // ---------------------------------------------------------------- errori
  @override
  String get errorWrongCredentials => 'Email o password non corretti';
  @override
  String get errorEmailNotConfirmed => 'Email non ancora confermata';
  @override
  String errorLogin(String detail) => 'Accesso non riuscito: $detail';
  @override
  String errorPhotoUpload(String detail) => 'Caricamento foto non riuscito: $detail';
  @override
  String get errorOffline => 'Connessione assente: controlla internet e riprova';
  @override
  String get errorNotAuthorized => 'Questo account non è autorizzato a gestire il negozio.';

  // ---------------------------------------------------------------- accesso
  @override
  String get loginSubtitle => 'Gestione del negozio';
  @override
  String get loginEmail => 'Email';
  @override
  String get loginPassword => 'Password';
  @override
  String get loginMissingFields => 'Inserisci email e password';
  @override
  String get loginButton => 'Entra';

  // ---------------------------------------------------------------- navigazione
  @override
  String get tabProducts => 'Pezzi';
  @override
  String get tabChannels => "Canali d'ordine";

  // ---------------------------------------------------------------- pezzi
  @override
  String statusLabel(String status) => switch (status) {
        'disponibile' => 'Disponibile',
        'su_ordinazione' => 'Su ordinazione',
        'venduto' => 'Venduto',
        'nascosto' => 'Nascosto',
        _ => status,
      };
  @override
  String price(double? value) => value == null
      ? 'Prezzo su richiesta'
      : '${value.toStringAsFixed(2).replaceAll('.', ',')} €';

  @override
  String get productsTitle => 'I miei pezzi';
  @override
  String get trashTitle => 'Cestino';
  @override
  String get viewSite => 'Vedi il sito';
  @override
  String get openTrash => 'Cestino';
  @override
  String get closeTrash => 'Torna ai pezzi';
  @override
  String get newProduct => 'Nuovo pezzo';
  @override
  String get emptyProducts => 'Nessun pezzo ancora.\nPremi "Nuovo pezzo" per aggiungere il primo!';
  @override
  String get emptyTrash => 'Il cestino è vuoto.';

  @override
  String get actionSold => 'Segna come venduto';
  @override
  String get actionAvailable => 'Rimetti disponibile';
  @override
  String get actionHide => 'Nascondi dal sito';
  @override
  String get actionTrash => 'Sposta nel cestino';
  @override
  String get actionRestore => 'Ripristina';
  @override
  String get actionDeleteForever => 'Elimina per sempre';

  @override
  String get doneSold => 'Segnato come venduto';
  @override
  String get doneAvailable => 'Di nuovo disponibile';
  @override
  String get doneHidden => 'Nascosto dal sito';
  @override
  String get doneTrashed => 'Spostato nel cestino';
  @override
  String get doneRestored => 'Ripristinato';
  @override
  String get doneDeleted => 'Pezzo eliminato';
  @override
  String get doneAdded => 'Pezzo aggiunto: sul sito entro un minuto';
  @override
  String get doneSaved => 'Modifiche salvate';

  @override
  String get deleteForeverTitle => 'Eliminare per sempre?';
  @override
  String deleteForeverBody(String title) =>
      '"$title" e le sue foto verranno cancellati definitivamente.';

  // ---------------------------------------------------------------- scheda pezzo
  @override
  String get editNewTitle => 'Nuovo pezzo';
  @override
  String get editTitle => 'Modifica pezzo';

  @override
  String get photosSection => 'Foto';
  @override
  String get photosHint => 'La prima è la copertina. Tocca una foto per spostarla o rimuoverla.';
  @override
  String get photoCover => 'Copertina';
  @override
  String get photoAdd => 'Aggiungi';
  @override
  String get photoMakeCover => 'Usa come copertina';
  @override
  String get photoMoveLeft => 'Sposta a sinistra';
  @override
  String get photoMoveRight => 'Sposta a destra';
  @override
  String get photoRemove => 'Rimuovi foto';
  @override
  String photosMax(int max) => 'Puoi avere al massimo $max foto';
  @override
  String photosOpenError(String detail) => 'Non riesco ad aprire le foto: $detail';
  @override
  String photosPartiallyAdded(int added, int max) =>
      'Aggiunte solo $added foto: il massimo è $max';
  @override
  String photosSkipped(int count) =>
      '$count foto non aggiunte: formato non supportato o file troppo grande';

  @override
  String get productSection => 'Il pezzo';
  @override
  String get fieldName => 'Nome *';
  @override
  String get fieldDescription => 'Descrizione';
  @override
  String get fieldPrice => 'Prezzo €';
  @override
  String get fieldPriceHelp => 'Vuoto = su richiesta';
  @override
  String get fieldCompare => 'Prezzo barrato €';
  @override
  String get fieldCompareHelp => 'Solo per i saldi';
  @override
  String get statusSection => 'Stato';

  @override
  String get optionsSection => 'Opzioni';
  @override
  String get optionsHint => 'Le scelte che fa il cliente, ad esempio colori o misure.';
  @override
  String get optionName => 'Nome (es. Colore)';
  @override
  String get optionValues => 'Scelte, separate da virgola';
  @override
  String get optionValuesHint => 'Verde, Rosa, Azzurro';
  @override
  String get optionRemove => 'Rimuovi opzione';
  @override
  String get optionAdd => 'Aggiungi opzione';

  @override
  String get vintedSection => 'Vinted';
  @override
  String get vintedHint => 'Se il pezzo è anche in vendita su Vinted.';
  @override
  String get vintedField => "Link all'annuncio (facoltativo)";

  @override
  String get errTitleRequired => 'Scrivi il nome del pezzo';
  @override
  String get errPriceFormat => 'Scrivi un numero, es. 25 o 12,50';
  @override
  String get errPriceInvalid => 'Prezzo non valido';
  @override
  String get errCompareNeedsPrice => 'Serve anche il prezzo attuale';
  @override
  String get errCompareTooLow => 'Deve essere più alto del prezzo';
  @override
  String get errVintedLink => "Incolla il link dell'annuncio (https://www.vinted.it/...)";
  @override
  String get errOptionName => 'Scrivi il nome';
  @override
  String get errOptionValuesEmpty => 'Scrivi almeno una scelta';
  @override
  String errOptionValuesMax(int max) => 'Massimo $max scelte';
  @override
  String errOptionValueLength(int max) => 'Ogni scelta al massimo $max caratteri';
  @override
  String get errSlug => 'Non riesco a creare un indirizzo unico per questo pezzo';

  @override
  String get progressSaving => 'Salvo…';
  @override
  String progressUploading(int done, int total) => 'Carico la foto $done di $total…';

  // ---------------------------------------------------------------- canali d'ordine
  @override
  String get channelsTitle => "Canali d'ordine";
  @override
  String channelsIntro(String placeholders) =>
      'Sul sito compariranno i pulsanti dei canali attivi. '
      'Nei messaggi puoi usare $placeholders: '
      'vengono sostituiti con il pezzo scelto dal cliente.';
  @override
  String get saveAndPublish => 'Salva e pubblica';
  @override
  String get channelsSaved => 'Salvato! Il sito si aggiorna entro un minuto';
  @override
  String get channelsPublishNote => "Canali d'ordine aggiornati";

  @override
  String get whatsapp => 'WhatsApp';
  @override
  String get whatsappSubtitle => 'Il cliente ti scrive con il messaggio già pronto';
  @override
  String get phoneField => 'Numero';
  @override
  String get phoneHelp => 'Con prefisso, es. +39 333 1234567';
  @override
  String get phoneRequired => 'Inserisci il numero';
  @override
  String get phoneInvalid => 'Numero non valido';
  @override
  String get templateField => 'Messaggio precompilato';

  @override
  String get emailChannel => 'Email';
  @override
  String get emailSubtitle => "Si apre l'app email con oggetto e testo pronti";
  @override
  String get emailField => 'Indirizzo email';
  @override
  String get emailRequired => "Inserisci l'indirizzo";
  @override
  String get emailInvalid => 'Indirizzo non valido';
  @override
  String get emailSubject => 'Oggetto';
  @override
  String get emailBody => 'Testo';

  @override
  String get vintedChannel => 'Vinted';
  @override
  String get vintedSubtitle => 'Link al tuo profilo Vinted';
  @override
  String get instagramChannel => 'Instagram';
  @override
  String get instagramSubtitle => 'Link al tuo profilo Instagram';
  @override
  String get profileLink => 'Link al profilo';
  @override
  String get linkRequired => 'Inserisci il link';
  @override
  String get vintedInvalid => 'Deve iniziare con https://www.vinted.it/';
  @override
  String get instagramInvalid => 'Deve iniziare con https://www.instagram.com/';

  @override
  String get templateTooLong => 'Testo troppo lungo';
  @override
  String templateInvalid(String placeholders) => 'Tra graffe puoi usare solo: $placeholders';
}
