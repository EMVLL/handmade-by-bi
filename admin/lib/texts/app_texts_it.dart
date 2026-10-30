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
  @override
  String get loginRemember => 'Rimani connesso';
  @override
  String get loginRememberHint => 'Su questo telefono non dovrai rifare l\'accesso';

  // ---------------------------------------------------------------- navigazione
  @override
  String get tabProducts => 'Pezzi';
  @override
  String get tabCategories => 'Categorie';
  @override
  String get tabChannels => 'Contatti';

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
  String get optionsHint =>
      'Le scelte che fa il cliente, ad esempio taglia o colore. Se non servono, lascia vuoto.';
  @override
  String get optionName => 'Che cosa sceglie il cliente?';
  @override
  List<String> get optionNameSuggestions => const ['Colore', 'Taglia', 'Misura'];
  @override
  String get optionValues => 'Scelte';
  @override
  String get choiceInput => 'Aggiungi una scelta';
  @override
  String get choiceInputHint => 'es. 25,5 oppure M — poi premi +';
  @override
  String get colorChoiceHint => 'es. Rosa antico — se riconosco il colore compare il pallino';
  @override
  String get choiceAdd => 'Aggiungi';
  @override
  String get choiceAlreadyPresent => "Questa scelta c'è già";
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

  // ---------------------------------------------------------------- categorie
  @override
  String get categoriesTitle => 'Categorie';
  @override
  String get categoriesAutoTitle => 'Categorie automatiche';
  @override
  String categoriesAutoReady(int count) =>
      'Disponibili in pronta consegna: ${productsCount(count)} (quelli con stato Disponibile)';
  @override
  String categoriesAutoOther(int count) => 'Altro: ${productsCount(count)} (quelli senza categoria)';
  @override
  String get categoriesAutoNote => 'Non devi crearle né aggiornarle: il sito le calcola da solo.';
  @override
  String productsCount(int count) => count == 1 ? '1 pezzo' : '$count pezzi';
  @override
  String get categoriesEmpty => 'Nessuna categoria.\nPremi "Nuova categoria" per crearne una.';
  @override
  String get categoryNew => 'Nuova categoria';
  @override
  String get categoryNameField => 'Nome della categoria';
  @override
  String get categoryNameRequired => 'Scrivi un nome';
  @override
  String get categoryRename => 'Rinomina';
  @override
  String get categoryMoveUp => 'Sposta su';
  @override
  String get categoryMoveDown => 'Sposta giù';
  @override
  String get categoryDeleteTitle => 'Eliminare la categoria?';
  @override
  String categoryDeleteBody(String name) =>
      'I pezzi di "$name" non vengono cancellati: se non hanno altre categorie finiscono in "Altro".';
  @override
  String get categoryReserved => '"Altro" e "Pronta consegna" esistono già in automatico';
  @override
  String get categorySaved => 'Fatto! Il sito si aggiorna entro un minuto';
  @override
  String get editCategoriesSection => 'Categorie';
  @override
  String get editCategoriesHint =>
      'Puoi sceglierne più di una. Se non ne scegli nessuna, il pezzo va in "Altro".';
  @override
  String get editNoCategories => 'Non ci sono ancora categorie: creale nella scheda Categorie.';
  @override
  String get filterAll => 'Tutti';
  @override
  String get filterNoCategory => 'Senza categoria';

  // ---------------------------------------------------------------- il mio negozio
  @override
  String get tabShop => 'Negozio';
  @override
  String get shopTitle => 'Il mio negozio';
  @override
  String get shopIntro =>
      'Qui decidi come appare il sito. Le modifiche restano in anteprima: '
      'le vedi nella scheda Anteprima e vanno online solo quando premi Pubblica. '
      'Pezzi e categorie invece si aggiornano subito.';
  @override
  String get shopStyle => 'Stile del sito';
  @override
  String get shopStyleHint => 'Colori, caratteri e angoli';
  @override
  String get shopIdentity => 'Nome, logo e Google';
  @override
  String get shopIdentityHint => 'Come si chiama il negozio e come appare nelle ricerche';
  @override
  String get shopHome => 'Pagina iniziale';
  @override
  String get shopHomeHint => 'Le sezioni della home: testi, foto, ordine';
  @override
  String get shopHistory => 'Cronologia';
  @override
  String get shopHistoryHint => 'Torna a una versione precedente del sito';
  @override
  String get savedLive => 'Fatto! Il sito si aggiorna in pochi secondi';
  @override
  String get saved => 'Salvato';
  @override
  String get savedDraft => 'Salvato in anteprima. Quando sei pronta, premi Pubblica nella scheda Anteprima';

  // Stile
  @override
  String get styleTitle => 'Stile del sito';
  @override
  String get stylePresets => 'Stili pronti';
  @override
  String get styleColors => 'Colori';
  @override
  String get colorPrimary => 'Colore principale';
  @override
  String get colorAccent => 'Colore secondario';
  @override
  String get colorBackground => 'Sfondo';
  @override
  String get colorText => 'Testo';
  @override
  String get styleHeadingFont => 'Carattere dei titoli';
  @override
  String get styleBodyFont => 'Carattere del testo';
  @override
  String get styleCorners => 'Angoli';
  @override
  List<String> get cornerLabels => const ['Squadrati', 'Poco arrotondati', 'Arrotondati', 'Molto arrotondati'];
  @override
  String get stylePreviewTitle => 'Fatto a mano';
  @override
  String get stylePreviewText => 'Così appariranno titoli, testi e bottoni sul sito.';
  @override
  String get stylePreviewButton => 'Ordina';
  @override
  String get stylePreviewTag => 'Novità';
  @override
  String get colorPickerTitle => 'Scegli un colore';
  @override
  String get colorHex => 'Oppure scrivi il codice (es. #B5838D)';
  @override
  String get colorHexInvalid => 'Codice non valido';
  @override
  String presetName(String key) => switch (key) {
        'rosa' => 'Rosa antico',
        'salvia' => 'Salvia',
        'lavanda' => 'Lavanda',
        'mare' => 'Mare',
        'terracotta' => 'Terracotta',
        'cioccolato' => 'Panna e cioccolato',
        _ => key,
      };
  @override
  String get noteStyle => 'Stile del sito aggiornato';

  // Nome, logo e Google
  @override
  String get identityTitle => 'Nome, logo e Google';
  @override
  String get siteName => 'Nome del negozio';
  @override
  String get logo => 'Logo';
  @override
  String get logoHint => 'Se non metti un logo, in alto compare il nome del negozio.';
  @override
  String get seoSection => 'Come appare su Google e quando condividi il link';
  @override
  String get seoTitle => 'Titolo';
  @override
  String get seoDescription => 'Descrizione breve';
  @override
  String get seoImage => 'Immagine di anteprima';
  @override
  String get noteIdentity => 'Nome, logo e Google aggiornati';

  // Pagina iniziale e sezioni
  @override
  String get homeTitle => 'Pagina iniziale';
  @override
  String get homeIntro =>
      'Le sezioni compaiono sul sito in quest\'ordine. Tocca una sezione per cambiarne testi, foto e aspetto.';
  @override
  String get addSection => 'Aggiungi sezione';
  @override
  String get addSectionTitle => 'Che sezione vuoi aggiungere?';
  @override
  String get sectionHidden => 'Nascosta';
  @override
  String get sectionShow => 'Mostra sul sito';
  @override
  String get sectionHide => 'Nascondi dal sito';
  @override
  String get sectionEdit => 'Modifica';
  @override
  String get sectionDeleteTitle => 'Eliminare la sezione?';
  @override
  String sectionDeleteBody(String label) =>
      'La sezione "$label" sparisce dal sito. Se cambi idea puoi tornare indietro dalla Cronologia.';
  @override
  String blockDescription(String type) => switch (type) {
        'hero' => 'La grande immagine iniziale, con titolo e bottone',
        'category_menu' => 'I riquadri per scegliere una categoria',
        'product_grid' => 'I tuoi lavori: tutti oppure di una categoria',
        'featured_product' => 'Un solo pezzo in grande, da mettere in risalto',
        'text' => 'Un titolo e qualche paragrafo, ad esempio "Chi sono"',
        'gallery' => 'Più foto insieme, in griglia o a scorrimento',
        'testimonials' => 'Cosa dicono di te i clienti',
        'faq' => 'Domande e risposte che si aprono con un tocco',
        'contact' => 'I pulsanti per scriverti',
        'banner' => 'Una striscia colorata con un avviso',
        'spacer' => 'Un po\' di spazio o una linea tra le sezioni',
        _ => '',
      };
  @override
  String noteSectionEdited(String label) => 'Modificata la sezione "$label"';
  @override
  String noteSectionAdded(String label) => 'Aggiunta la sezione "$label"';
  @override
  String noteSectionRemoved(String label) => 'Eliminata la sezione "$label"';
  @override
  String get noteSectionsOrder => 'Cambiato l\'ordine delle sezioni';
  @override
  String noteSectionVisibility(String label) => 'Mostrata/nascosta la sezione "$label"';

  // Modulo di una sezione
  @override
  String get formStyleSection => 'Aspetto: sfondo e carattere del titolo';
  @override
  String get fieldRequired => 'Questo campo serve';
  @override
  String get linkHelp => 'Una pagina del sito (tocca un suggerimento) oppure un indirizzo che inizia con https://';
  @override
  String get linkInvalid => 'Deve iniziare con / oppure con https://';
  @override
  String get linkAllProducts => 'Tutti i lavori';
  @override
  String get choosePhoto => 'Scegli foto';
  @override
  String get changePhoto => 'Cambia';
  @override
  String get removePhoto => 'Togli';
  @override
  String get uploading => 'Carico la foto…';
  @override
  String get addPhotos => 'Aggiungi foto';
  @override
  String get allCategories => 'Tutte';
  @override
  String get chooseProduct => 'Scegli il pezzo';
  @override
  String get noProduct => 'Nessun pezzo scelto';
  @override
  String get addItem => 'Aggiungi';
  @override
  String get removeItem => 'Togli';

  // Cronologia
  @override
  String get historyTitle => 'Cronologia';
  @override
  String get historyIntro =>
      'Ogni volta che pubblichi, il sito ne tiene una copia. Tocca una versione per riportarla in anteprima: '
      'la controlli e, se va bene, premi Pubblica. I pezzi e le categorie non cambiano.';
  @override
  String get historyLive => 'Online adesso';
  @override
  String get historyRestoreTitle => 'Tornare a questa versione?';
  @override
  String historyRestoreBody(String when) =>
      'L\'anteprima tornerà com\'era il $when: stile, testi e sezioni. '
      'Il sito online cambia solo quando premi Pubblica.';
  @override
  String get historyRestore => 'Riporta in anteprima';
  @override
  String get historyRestored => 'Fatto! Il sito è tornato alla versione scelta';

  // Categoria
  @override
  String get categoryEditTitle => 'Categoria';
  @override
  String get categoryDescription => 'Descrizione (compare sotto il titolo della categoria)';
  @override
  String get categoryCover => 'Foto di copertina';
  @override
  String get categoryCoverHint => 'Se non scegli una foto, si usa quella del primo pezzo della categoria.';
  @override
  String get categoryMenuLook => 'Come appare il menu sul sito';
  @override
  String get categoryMenuLookHint => 'Riquadri, cerchi, scorrimento o pulsanti; titolo e foto';
  @override
  String get categoryMenuMissing => 'Il menu categorie non è nella pagina iniziale: aggiungilo da Negozio → Pagina iniziale.';

  // ---------------------------------------------------------------- anteprima
  @override
  String get tabPreview => 'Anteprima';
  @override
  String get previewTitle2 => 'Anteprima del sito';
  @override
  String get previewChanges => 'Ci sono modifiche non ancora pubblicate';
  @override
  String get previewNoChanges => 'Il sito online è uguale a questa anteprima';
  @override
  String get publish => 'Pubblica';
  @override
  String get publishing => 'Pubblico…';
  @override
  String get published => 'Pubblicato! Il sito si aggiorna in pochi secondi';
  @override
  String get discard => 'Annulla modifiche';
  @override
  String get discardTitle => 'Annullare le modifiche?';
  @override
  String get discardBody =>
      'L\'anteprima torna uguale al sito online. Le modifiche non pubblicate andranno perse.';
  @override
  String get discarded => 'Modifiche annullate';
  @override
  String get reload => 'Aggiorna';
  @override
  String get notePublish => 'Pubblicazione dall\'anteprima';
  @override
  String get historyLoaded => 'Versione riportata in anteprima: controllala e premi Pubblica';

  // ---------------------------------------------------------------- canali d'ordine
  @override
  String get channelsTitle => "Canali d'ordine";
  @override
  String get channelsIntro =>
      'Scegli come i clienti possono ordinarti: sul sito comparirà '
      'un pulsante per ogni canale attivo.';
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
  String get vintedInvalid => 'Incolla il link del tuo profilo Vinted';
  @override
  String get instagramInvalid => 'Scrivi il nome utente o incolla il link del profilo';
  @override
  String get vintedLinkHelp => 'Su Vinted apri il tuo profilo, tocca Condividi → Copia link e incollalo qui';
  @override
  String get instagramLinkHelp => 'Il tuo nome utente (es. @handmadebybi) oppure il link del profilo';

  // Messaggi precompilati
  @override
  String get messageSectionWhatsapp => 'Messaggio già scritto per il cliente (facoltativo)';
  @override
  String get messageSectionEmail => "Oggetto e testo dell'email (facoltativo)";
  @override
  String get messageHelp =>
      'Quando il cliente preme il pulsante, trova il messaggio già scritto e deve solo inviarlo. '
      'Va già bene così: cambialo solo se vuoi. Con i pulsanti qui sotto inserisci i dati del pezzo, '
      'che verranno scritti in automatico (guarda l\'esempio).';
  @override
  String get tokenProduct => 'Nome del pezzo';
  @override
  String get tokenPrice => 'Prezzo';
  @override
  String get tokenOption => 'Scelte del cliente';
  @override
  String get tokenLink => 'Link al pezzo';
  @override
  String get previewTitle => 'Esempio di come lo riceverai:';
  @override
  String get resetMessage => 'Ripristina il testo standard';
  @override
  String get defaultWhatsappTemplate => 'Ciao! Vorrei ordinare {prodotto} ({prezzo}). {opzione} {link}';
  @override
  String get defaultEmailSubject => 'Ordine: {prodotto}';
  @override
  String get defaultEmailBody => 'Ciao! Vorrei ordinare {prodotto} ({prezzo}). {opzione} {link}';
  @override
  String get sampleProduct => 'Borsa Margherita';
  @override
  String get sampleOption => 'Colore: Rosa';
  @override
  String get templateTooLong => 'Testo troppo lungo';
  @override
  String get templateInvalid => 'Tra graffe { } usa solo i dati dei pulsanti qui sotto';
}
