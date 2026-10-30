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
  String get loginRemember;
  String get loginRememberHint;

  // ---------------------------------------------------------------- navigazione
  String get tabProducts;
  String get tabCategories;
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
  List<String> get optionNameSuggestions;
  String get optionValues;
  String get choiceInput;
  String get choiceInputHint;
  String get colorChoiceHint;
  String get choiceAdd;
  String get choiceAlreadyPresent;
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

  // ---------------------------------------------------------------- categorie
  String get categoriesTitle;
  String get categoriesAutoTitle;
  String categoriesAutoReady(int count);
  String categoriesAutoOther(int count);
  String get categoriesAutoNote;
  String productsCount(int count);
  String get categoriesEmpty;
  String get categoryNew;
  String get categoryNameField;
  String get categoryNameRequired;
  String get categoryRename;
  String get categoryMoveUp;
  String get categoryMoveDown;
  String get categoryDeleteTitle;
  String categoryDeleteBody(String name);
  String get categoryReserved;
  String get categorySaved;
  String get editCategoriesSection;
  String get editCategoriesHint;
  String get editNoCategories;
  String get filterAll;
  String get filterNoCategory;

  // ---------------------------------------------------------------- il mio negozio
  String get tabShop;
  String get shopTitle;
  String get shopIntro;
  String get shopStyle;
  String get shopStyleHint;
  String get shopIdentity;
  String get shopIdentityHint;
  String get shopHome;
  String get shopHomeHint;
  String get shopHistory;
  String get shopHistoryHint;
  String get savedLive;
  String get savedDraft;
  String get saved;

  // Stile
  String get styleTitle;
  String get stylePresets;
  String get styleColors;
  String get colorPrimary;
  String get colorAccent;
  String get colorBackground;
  String get colorText;
  String get styleHeadingFont;
  String get styleBodyFont;
  String get styleCorners;
  List<String> get cornerLabels;
  String get stylePreviewTitle;
  String get stylePreviewText;
  String get stylePreviewButton;
  String get stylePreviewTag;
  String get colorPickerTitle;
  String get colorHex;
  String get colorHexInvalid;
  String presetName(String key);
  String get noteStyle;

  // Nome, logo e Google
  String get identityTitle;
  String get siteName;
  String get logo;
  String get logoHint;
  String get seoTitle;
  String get seoDescription;
  String get seoImage;
  String get seoSection;
  String get noteIdentity;

  // Pagina iniziale e sezioni
  String get homeTitle;
  String get homeIntro;
  String get addSection;
  String get addSectionTitle;
  String get sectionHidden;
  String get sectionShow;
  String get sectionHide;
  String get sectionEdit;
  String get sectionDeleteTitle;
  String sectionDeleteBody(String label);
  String blockDescription(String type);
  String noteSectionEdited(String label);
  String noteSectionAdded(String label);
  String noteSectionRemoved(String label);
  String get noteSectionsOrder;
  String noteSectionVisibility(String label);

  // Modulo di una sezione
  String get formStyleSection;
  String get fieldRequired;
  String get linkHelp;
  String get linkInvalid;
  String get linkAllProducts;
  String get choosePhoto;
  String get changePhoto;
  String get removePhoto;
  String get uploading;
  String get addPhotos;
  String get allCategories;
  String get chooseProduct;
  String get noProduct;
  String get addItem;
  String get removeItem;

  // Cronologia
  String get historyTitle;
  String get historyIntro;
  String get historyLive;
  String get historyRestoreTitle;
  String historyRestoreBody(String when);
  String get historyRestore;
  String get historyRestored;

  // Categoria
  String get categoryEditTitle;
  String get categoryDescription;
  String get categoryCover;
  String get categoryCoverHint;
  String get categoryMenuLook;
  String get categoryMenuLookHint;
  String get categoryMenuMissing;

  // ---------------------------------------------------------------- anteprima
  String get tabPreview;
  String get previewTitle2;
  String get previewChanges;
  String get previewNoChanges;
  String get publish;
  String get publishing;
  String get published;
  String get discard;
  String get discardTitle;
  String get discardBody;
  String get discarded;
  String get reload;
  String get notePublish;
  String get historyLoaded;

  // ---------------------------------------------------------------- canali d'ordine
  String get channelsTitle;
  String get channelsIntro;
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

  String get vintedLinkHelp;
  String get instagramLinkHelp;

  // Messaggi precompilati
  String get messageSectionWhatsapp;
  String get messageSectionEmail;
  String get messageHelp;
  String get tokenProduct;
  String get tokenPrice;
  String get tokenOption;
  String get tokenLink;
  String get previewTitle;
  String get resetMessage;
  String get defaultWhatsappTemplate;
  String get defaultEmailSubject;
  String get defaultEmailBody;
  String get sampleProduct;
  String get sampleOption;
  String get templateTooLong;
  String get templateInvalid;
}
