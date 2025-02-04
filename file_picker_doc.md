Installation:
Add the latest file_picker as a dependency in your pubspec.yaml file.


Setup:
Android
All set, you should be ready to go as long as you concede runtime permissions (included with the plugin)!

Also lately, since Android 11 compatibility was added, you may want to make sure that you're using one of the compatible gradle versions or else you may encounter build issues such as <query> tag not being recognized.

For release builds you need to exclude androidx.lifecycle.DefaultLifecycleObserver from being obfuscated. You do that by adding a file called proguard-rules.pro in the android/app folder and fill it with the following rule: -keep class androidx.lifecycle.DefaultLifecycleObserver

Note: If your are overriding onActivityResult in your MainActivity, make sure to call super.onActivityResult(...) for unhandled activities. Otherwise picking a file might fail silently.

 iOS
Since 1.7.0 sub-dependencies, you will need to add use_frameworks! to your <project root>/ios/Podfile.

target 'Runner' do
  use_frameworks!
Optional permissions
You can prevent the need for certain permissions by excluding compilation of Media, Audio or Documents picker respectively. This is achieved by including in the file <project root>/ios/Podfile the line Pod::PICKER_MEDIA = false, resp. Pod::PICKER_AUDIO = false, resp. Pod::PICKER_DOCUMENT = false before the line target 'Runner' do.

(If you do use a file picker that is included an error will be logged and no dialog is shown.)

Based on the location of the files that you are willing to pick paths, you may need to add some keys to your iOS app's Info.plist file, located in <project root>/ios/Runner/Info.plist:

UIBackgroundModes with the fetch and remote-notifications keys - Required if you'll be using the FileType.any or FileType.custom. Describe why your app needs to access background taks, such downloading files (from cloud services). This is called Required background modes, with the keys App download content from network and App downloads content in response to push notifications respectively in the visual editor (since both methods aren't actually overriden, not adding this property/keys may only display a warning, but shouldn't prevent its correct usage).

<key>UIBackgroundModes</key>
<array>
   <string>fetch</string>
   <string>remote-notification</string>
</array>
NSAppleMusicUsageDescription - Required if you'll be using the FileType.audio. Describe why your app needs permission to access music library. This is called Privacy - Media Library Usage Description in the visual editor.

<key>NSAppleMusicUsageDescription</key>
<string>Explain why your app uses music</string>
UISupportsDocumentBrowser - Required if you'll want to write directly on directories. This way iOS creates an app folder for the app and the user can create and pick directories within the folder and the app has the permission to write here.

<key>UISupportsDocumentBrowser</key>
<true/>
LSSupportsOpeningDocumentsInPlace - Required if you'll want to open the original file instead of caching it (when using FileType.all).

<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
NSPhotoLibraryUsageDescription - Required if you'll be using the FileType.image or FileType.video. Describe why your app needs permission for the photo library. This is called Privacy - Photo Library Usage Description in the visual editor.

<key>NSPhotoLibraryUsageDescription</key>
<string>Explain why your app uses photo library</string>
Note: Any iOS version below 11.0, will require an Apple Developer Program account to enable CloudKit and make it possible to use the document picker (which happens when you select FileType.all, FileType.custom or any other option with getMultiFilePath()). You can read more about it here.


API:

Filters
All the paths can be filtered using one of the following enumerations:

Filter	Description
FileType.any	Will let you pick all available files. On iOS it opens the Files app.
FileType.custom	Will let you pick a path for the extension matching the allowedExtensions provided. Opens Files app on iOS.
FileType.image	Will let you pick an image file. Opens gallery (Photos app) on iOS.
FileType.video	Will let you pick a video file. Opens gallery (Photos app) on iOS.
FileType.media	Will let you pick either video or images. Opens gallery (Photos app) on iOS.
FileType.audio	Will let you pick an audio file. Opens music on iOS and device must have Music app installed. Note that DRM protected files won't provide a path, null will be returned instead.
Parameters
There are a few common parameters that all picking methods support, those are listed below:

Parameter	Type	Description	Supported Platforms	Default
allowedExtensions	List<String>?	Accepts a list of allowed extensions to be filtered. Eg. [pdf, jpg]	All	-
allowCompression	bool	Defines whether image and/or video files should be compressed automatically by OS when picked. When set, Live Photos will also be converted to static JPEG images. On Android has no effect as it always returns the original or integral file copy.	iOS	true
dialogTitle	String?	The title to be set on desktop platforms modal dialog. Hasn't any effect on Web or Mobile.	Desktop	File Picker
initialDirectory	String?	Can be optionally set to an absolute path to specify where the dialog should open. Only supported on Linux, macOS, and Windows.	Desktop	-
lockParentWindow	bool	If true, then the child window (file picker window) will stay in front of the Flutter window until it is closed (like a modal window).	Desktop (only Windows)	false
onFileLoading	Function(FilePickerStatus)?	When provided, will receive the processing status of picked files. This is particularly useful if you want to display a loading dialog or so when files are being downloaded/cached	Mobile & Web	-
type	FileType	Defines the type of the filtered files.	All	FileType.any
useFullScreenDialog	bool	Lets the developer set to use full screen dialog (UIModalPresentationFullScreen) or the platform default (typically UIModalPresentationFormSheet).	iOS (13+)	false
withData	bool	Sets if the file should be immediately loaded into memory and available as Uint8List on its PlatformFile instance.	Mobile & Web	true on Web, false everywhere else
withReadStream	bool	Allows the file to be read into a Stream<List<int>> instead of immediately loading it into memory, to prevent high usage, specially with bigger files. If you want an example on how to use it, check it here.	Mobile & Web	false
Methods
◉ pickFiles()
This is the main method to pick files and provides all the properties mentioned before. Will return a FilePickerResult — containing the List<PlatformFile>> — or null if picker is aborted.

NOTE: You must use FileType.custom when providing allowedExtensions, else it will throw an exception.

NOTE 2: On web the path will always be null as web always use fake paths, you should use the bytes instead to retrieve the picked file data.

Usage example
// Lets the user pick one file; files with any file extension can be selected
FilePickerResult result = await FilePicker.platform.pickFiles(type: FileType.any);

// The result will be null, if the user aborted the dialog
if(result != null) {
 File file = File(result.files.first.path);
}

// Lets the user pick one file, but only files with the extensions `svg` and `pdf` can be selected
FilePickerResult result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['svg', 'pdf']);

// The result will be null, if the user aborted the dialog
if(result != null) {
 File file = File(result.files.first.path);
}
◉ getDirectoryPath()
Opens a folder picker dialog which lets the user select a directory path. Returns the absolute path to the selected directory. Returns null, if the user canceled the dialog or if the folder path couldn't be resolved.

Optionally, you can set the title of the dialog via the parameter dialogTitle. The parameter initialDirectory can be optionally set to an absolute path to specify where the dialog should open. This parameter only works on Linux and macOS (Windows implementation is missing).

On Windows, you can also set lockParentWindow to true to make the dialog always stay in foreground like a modal.

Platform	Info
iOS	Requires iOS 11 or above
Android	Requires SDK 21 or above
Desktop	Supported
Web	Not supported
◉ clearTemporaryFiles()
An utility method that will explicitly prune cached files from the picker. This is not required as the system will take care on its own, however, sometimes you may want to remove them, specially if your app handles a lot of files.

Platform	Info
iOS	All picked files are cached, so this will immediately remove them.
Android	Since 2.0.0, all picked files are cached, so this will immediately remove them.
Desktop & Web	Not implemented as it won't have any effect. Paths are always referencing the original files.
◉ saveFile()
Opens a save-file / save-as dialog which lets the user select a file path and a file name to save a file. This function does not actually save a file. It only opens the dialog to let the user choose a location and file name. This function only returns the path to this (non-existing) file as a String. Returns null, if the user canceled the dialog.

Optionally, you can set the title of the dialog via the parameter dialogTitle, a default file name via the parameter fileName, and the initial directory where the dialog should open via the parameter initialDirectory. On Windows, you can also set lockParentWindow to true to make the dialog always stay in foreground like a modal. The parameters type and allowedExtensions can be used to set a list of valid file types. Please note that both parameters are just a proposal to the user as the save-file / save-as dialog does not enforce these restrictions.

NOTE: You must use FileType.custom when providing allowedExtensions, else it will throw an exception.

Platform	Info
iOS	Not supported
Android	Not supported
Desktop	Supported
Web	Not supported






Usage 
Quick simple usage example:

Single file
FilePickerResult? result = await FilePicker.platform.pickFiles();

if (result != null) {
  File file = File(result.files.single.path!);
} else {
  // User canceled the picker
}
Multiple files
FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

if (result != null) {
  List<File> files = result.paths.map((path) => File(path!)).toList();
} else {
  // User canceled the picker
}
Multiple files with extension filter
FilePickerResult? result = await FilePicker.platform.pickFiles(
  allowMultiple: true,
  type: FileType.custom,
  allowedExtensions: ['jpg', 'pdf', 'doc'],
);
Pick a directory
String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

if (selectedDirectory == null) {
  // User canceled the picker
}
Save-file / save-as dialog
String? outputFile = await FilePicker.platform.saveFile(
  dialogTitle: 'Please select an output file:',
  fileName: 'output-file.pdf',
);

if (outputFile == null) {
  // User canceled the picker
}
Load result and file details 
FilePickerResult? result = await FilePicker.platform.pickFiles();

if (result != null) {
  PlatformFile file = result.files.first;

  print(file.name);
  print(file.bytes);
  print(file.size);
  print(file.extension);
  print(file.path);
} else {
  // User canceled the picker
}
Retrieve all files as XFiles or individually 
FilePickerResult? result = await FilePicker.platform.pickFiles();

if (result != null) {
  // All files
  List<XFile> xFiles = result.xFiles;

  // Individually
  XFile xFile = result.files.first.xFile;
} else {
  // User canceled the picker
}
Pick and upload a file to Firebase Storage with Flutter Web
FilePickerResult? result = await FilePicker.platform.pickFiles();

if (result != null) {
  Uint8List fileBytes = result.files.first.bytes;
  String fileName = result.files.first.name;
  
  // Upload file
  await FirebaseStorage.instance.ref('uploads/$fileName').putData(fileBytes);
}
For full usage details refer to the Wiki above.








EXAMPLE dart:

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FilePickerDemo extends StatefulWidget {
  @override
  _FilePickerDemoState createState() => _FilePickerDemoState();
}

class _FilePickerDemoState extends State<FilePickerDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _defaultFileNameController = TextEditingController();
  final _dialogTitleController = TextEditingController();
  final _initialDirectoryController = TextEditingController();
  final _fileExtensionController = TextEditingController();
  String? _fileName;
  String? _saveAsFileName;
  List<PlatformFile>? _paths;
  String? _directoryPath;
  String? _extension;
  bool _isLoading = false;
  bool _lockParentWindow = false;
  bool _userAborted = false;
  bool _multiPick = false;
  FileType _pickingType = FileType.any;

  @override
  void initState() {
    super.initState();
    _fileExtensionController
        .addListener(() => _extension = _fileExtensionController.text);
  }

  void _pickFiles() async {
    _resetState();
    try {
      _directoryPath = null;
      _paths = (await FilePicker.platform.pickFiles(
        compressionQuality: 30,
        type: _pickingType,
        allowMultiple: _multiPick,
        onFileLoading: (FilePickerStatus status) => print(status),
        allowedExtensions: (_extension?.isNotEmpty ?? false)
            ? _extension?.replaceAll(' ', '').split(',')
            : null,
        dialogTitle: _dialogTitleController.text,
        initialDirectory: _initialDirectoryController.text,
        lockParentWindow: _lockParentWindow,
      ))
          ?.files;
    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _fileName =
          _paths != null ? _paths!.map((e) => e.name).toString() : '...';
      _userAborted = _paths == null;
    });
  }

  void _clearCachedFiles() async {
    _resetState();
    try {
      bool? result = await FilePicker.platform.clearTemporaryFiles();
      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            (result!
                ? 'Temporary files removed with success.'
                : 'Failed to clean temporary files'),
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );
    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectFolder() async {
    _resetState();
    try {
      String? path = await FilePicker.platform.getDirectoryPath(
        dialogTitle: _dialogTitleController.text,
        initialDirectory: _initialDirectoryController.text,
        lockParentWindow: _lockParentWindow,
      );
      setState(() {
        _directoryPath = path;
        _userAborted = path == null;
      });
    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFile() async {
    _resetState();
    try {
      String? fileName = await FilePicker.platform.saveFile(
        allowedExtensions: (_extension?.isNotEmpty ?? false)
            ? _extension?.replaceAll(' ', '').split(',')
            : null,
        type: _pickingType,
        dialogTitle: _dialogTitleController.text,
        fileName: _defaultFileNameController.text,
        initialDirectory: _initialDirectoryController.text,
        lockParentWindow: _lockParentWindow,
      );
      setState(() {
        _saveAsFileName = fileName;
        _userAborted = fileName == null;
      });
    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _logException(String message) {
    print(message);
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _resetState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
      _directoryPath = null;
      _fileName = null;
      _paths = null;
      _saveAsFileName = null;
      _userAborted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.deepPurple,
        ),
      ),
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('File Picker example app'),
        ),
        body: Padding(
          padding: const EdgeInsets.only(left: 5.0, right: 5.0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Configuration',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: [
                    SizedBox(
                      width: 400,
                      child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Dialog Title',
                        ),
                        controller: _dialogTitleController,
                      ),
                    ),
                    SizedBox(
                      width: 400,
                      child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Initial Directory',
                        ),
                        controller: _initialDirectoryController,
                      ),
                    ),
                    SizedBox(
                      width: 400,
                      child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Default File Name',
                        ),
                        controller: _defaultFileNameController,
                      ),
                    ),
                    SizedBox(
                      width: 400,
                      child: DropdownButtonFormField<FileType>(
                        value: _pickingType,
                        icon: const Icon(Icons.expand_more),
                        alignment: Alignment.centerLeft,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: FileType.values
                            .map(
                              (fileType) => DropdownMenuItem<FileType>(
                                child: Text(fileType.toString()),
                                value: fileType,
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(
                          () {
                            _pickingType = value!;
                            if (_pickingType != FileType.custom) {
                              _fileExtensionController.text = _extension = '';
                            }
                          },
                        ),
                      ),
                    ),
                    _pickingType == FileType.custom
                        ? SizedBox(
                            width: 400,
                            child: TextFormField(
                              decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'File Extension',
                                  hintText: 'jpg, png, gif'),
                              autovalidateMode: AutovalidateMode.always,
                              controller: _fileExtensionController,
                              keyboardType: TextInputType.text,
                              maxLength: 15,
                            ),
                          )
                        : SizedBox(),
                  ],
                ),
                SizedBox(
                  height: 20.0,
                ),
                Wrap(
                  alignment: WrapAlignment.start,
                  runAlignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  direction: Axis.horizontal,
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: [
                    SizedBox(
                      width: 400.0,
                      child: SwitchListTile.adaptive(
                        title: Text(
                          'Lock parent window',
                          textAlign: TextAlign.left,
                        ),
                        onChanged: (bool value) =>
                            setState(() => _lockParentWindow = value),
                        value: _lockParentWindow,
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints.tightFor(width: 400.0),
                      child: SwitchListTile.adaptive(
                        title: Text(
                          'Pick multiple files',
                          textAlign: TextAlign.left,
                        ),
                        onChanged: (bool value) =>
                            setState(() => _multiPick = value),
                        value: _multiPick,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 20.0,
                ),
                Divider(),
                SizedBox(
                  height: 20.0,
                ),
                Text(
                  'Actions',
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                  child: Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: <Widget>[
                      SizedBox(
                        width: 120,
                        child: FloatingActionButton.extended(
                            onPressed: () => _pickFiles(),
                            label:
                                Text(_multiPick ? 'Pick files' : 'Pick file'),
                            icon: const Icon(Icons.description)),
                      ),
                      SizedBox(
                        width: 120,
                        child: FloatingActionButton.extended(
                          onPressed: () => _selectFolder(),
                          label: const Text('Pick folder'),
                          icon: const Icon(Icons.folder),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: FloatingActionButton.extended(
                          onPressed: () => _saveFile(),
                          label: const Text('Save file'),
                          icon: const Icon(Icons.save_as),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: FloatingActionButton.extended(
                          onPressed: () => _clearCachedFiles(),
                          label: const Text('Clear temporary files'),
                          icon: const Icon(Icons.delete_forever),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(),
                SizedBox(
                  height: 20.0,
                ),
                Text(
                  'File Picker Result',
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Builder(
                  builder: (BuildContext context) => _isLoading
                      ? Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 40.0,
                                  ),
                                  child: const CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          ],
                        )
                      : _userAborted
                          ? Row(
                              children: [
                                Expanded(
                                  child: Center(
                                    child: SizedBox(
                                      width: 300,
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.error_outline,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 40.0),
                                        title: const Text(
                                          'User has aborted the dialog',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _directoryPath != null
                              ? ListTile(
                                  title: const Text('Directory path'),
                                  subtitle: Text(_directoryPath!),
                                )
                              : _paths != null
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20.0,
                                      ),
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.50,
                                      child: Scrollbar(
                                          child: ListView.separated(
                                        itemCount:
                                            _paths != null && _paths!.isNotEmpty
                                                ? _paths!.length
                                                : 1,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          final bool isMultiPath =
                                              _paths != null &&
                                                  _paths!.isNotEmpty;
                                          final String name = 'File $index: ' +
                                              (isMultiPath
                                                  ? _paths!
                                                      .map((e) => e.name)
                                                      .toList()[index]
                                                  : _fileName ?? '...');
                                          final path = kIsWeb
                                              ? null
                                              : _paths!
                                                  .map((e) => e.path)
                                                  .toList()[index]
                                                  .toString();

                                          return ListTile(
                                            title: Text(
                                              name,
                                            ),
                                            subtitle: Text(path ?? ''),
                                          );
                                        },
                                        separatorBuilder:
                                            (BuildContext context, int index) =>
                                                const Divider(),
                                      )),
                                    )
                                  : _saveAsFileName != null
                                      ? ListTile(
                                          title: const Text('Save file'),
                                          subtitle: Text(_saveAsFileName!),
                                        )
                                      : const SizedBox(),
                ),
                SizedBox(
                  height: 40.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}