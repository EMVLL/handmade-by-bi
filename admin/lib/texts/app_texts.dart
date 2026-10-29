import 'package:flutter/widgets.dart';

import 'app_texts_it.dart';

/// Lingua in uso nell'app. Tutti i testi si leggono da qui: `t.nomeTesto`.
///
/// Per aggiungere una lingua:
///   1. copia app_texts_it.dart in app_texts_en.dart
///   2. rinomina la classe in AppTextsEn e traduci i testi
///   3. assegna `t = AppTextsEn();` (e aggiungi Locale('en') in main.dart)
/// Il compilatore segnala ogni testo dimenticato, quindi una traduzione
/// incompleta non può arrivare all'app.
AppTexts t = AppTextsIt();

/// Elenco di tutti i testi dell'app.
abstract class AppTexts {
  Locale get locale;

  // ---------------------------------------------------------------- generali
  String get appName;
  String get retry;
  String get cancel;
  String get save;
  String get delete;
  String get signOut;
  String get checkFields;
  String maxChars(int max);

  // ---------------------------------------------------------------- errori
  String get errorWrongCredentials;
  String get errorEmailNotConfirmed;
  String errorLogin(String detail);
  String errorPhotoUpload(String detail);
  String get errorOffline;
  String get errorNotAuthorized;

  // ---------------------------------------------------------------- accesso
  String get loginSubtitle;
  String get loginEmail;
  String get loginPassword;
  String get loginMissingFields;
  String get loginButton;

  // ---------------------------------------------------------------- navigazione
  String get tabProducts;
  String get tabChannels;

  // ---------------------------------------------------------------- pezzi
  String statusLabel(String status);
  String price(double? value);

  String get productsTitle;
  String get trashTitle;
  String get viewSite;
  String get openTrash;
  String get closeTrash;
  String get newProduct;
  String get emptyProducts;
  String get emptyTrash;

  String get actionSold;
  String get actionAvailable;
  String get actionHide;
  String get actionTrash;
  String get actionRestore;
  String get actionDeleteForever;

  String get doneSold;
  String get doneAvailable;
  String get doneHidden;
  String get doneTrashed;
  String get doneRestored;
  String get doneDeleted;
  String get doneAdded;
  String get doneSaved;

  String get deleteForeverTitle;
  String deleteForeverBody(String title);

  // ---------------------------------------------------------------- scheda pezzo
  String get editNewTitle;
  String get editTitle;

  String get photosSection;
  String get photosHint;
  String get photoCover;
  String get photoAdd;
  String get photoMakeCover;
  String get photoMoveLeft;
  String get photoMoveRight;
  String get photoRemove;
  String photosMax(int max);
  String photosOpenError(String detail);
  String photosPartiallyAdded(int added, int max);
  String photosSkipped(int count);

  String get productSection;
  String get fieldName;
  String get fieldDescription;
  String get fieldPrice;
  String get fieldPriceHelp;
  String get fieldCompare;
  String get fieldCompareHelp;
  String get statusSection;

  String get optionsSection;
  String get optionsHint;
  String get optionName;
  String get optionValues;
  String get optionValuesHint;
  String get optionRemove;
  String get optionAdd;

  String get vintedSection;
  String get vintedHint;
  String get vintedField;

  String get errTitleRequired;
  String get errPriceFormat;
  String get errPriceInvalid;
  String get errCompareNeedsPrice;
  String get errCompareTooLow;
  String get errVintedLink;
  String get errOptionName;
  String get errOptionValuesEmpty;
  String errOptionValuesMax(int max);
  String errOptionValueLength(int max);
  String get errSlug;

  String get progressSaving;
  String progressUploading(int done, int total);

  // ---------------------------------------------------------------- canali d'ordine
  String get channelsTitle;
  String channelsIntro(String placeholders);
  String get saveAndPublish;
  String get channelsSaved;
  String get channelsPublishNote;

  String get whatsapp;
  String get whatsappSubtitle;
  String get phoneField;
  String get phoneHelp;
  String get phoneRequired;
  String get phoneInvalid;
  String get templateField;

  String get emailChannel;
  String get emailSubtitle;
  String get emailField;
  String get emailRequired;
  String get emailInvalid;
  String get emailSubject;
  String get emailBody;

  String get vintedChannel;
  String get vintedSubtitle;
  String get instagramChannel;
  String get instagramSubtitle;
  String get profileLink;
  String get linkRequired;
  String get vintedInvalid;
  String get instagramInvalid;

  String get templateTooLong;
  String templateInvalid(String placeholders);
}
