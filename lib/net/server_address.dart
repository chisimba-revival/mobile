/// Normalisation for the reserve office address as typed by a person.
///
/// Trimmed, without trailing slashes, and with a scheme when the operator
/// left one off: 'reserve.local:8080' is what somebody types and
/// 'http://reserve.local:8080' is what the client needs. Returns null when
/// nothing usable was entered, so callers can refuse rather than point at a
/// default the operator never chose.
///
/// Shared by the sign-in screen and settings: two fields that both change
/// where requests go must accept exactly the same spellings, or one of them
/// silently means something different.
String? normaliseServerAddress(String raw) {
  var url = raw.trim();
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  if (url.isEmpty) {
    return null;
  }
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'http://$url';
  }
  return url;
}
