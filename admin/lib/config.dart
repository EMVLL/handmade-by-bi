/// Dati di collegamento a Supabase.
///
/// La publishable key è pubblica per natura (la usa anche il sito):
/// può stare nel codice senza problemi. NON mettere mai qui la secret key.
class Config {
  static const supabaseUrl = 'https://fuqzlnrcyrivgeepogqf.supabase.co';
  static const supabaseKey = 'sb_publishable_8kybojNU13aJESMG5Z7Nzw_Hi2Dtudx';

  /// Indirizzo del sito pubblico, per il bottone "Vedi il sito".
  static const siteUrl = 'https://handmade-by-bi.netlify.app';

  // Limiti allineati a quelli del database.
  static const maxPhotos = 12;
  static const maxPhotoBytes = 5 * 1024 * 1024;
  static const maxOptions = 5;
  static const maxOptionValues = 20;
}
