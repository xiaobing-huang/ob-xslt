;;; ob-xslt.el --- org-babel functions for xslt evaluation -*- lexical-binding: t; -*-

;; Copyright (C) Dr. Ian FitzPatrick

;; Author: Dr. Ian FitzPatrick
;; Keywords: literate programming, reproducible research
;; Package-Requires: ((emacs "26.1"))
;; Homepage: https://orgmode.org
;; Version: 0.01

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; process xml documents with xslt from org babel
;;
;;; Code:
(require 'ob)
(require 'ob-ref)
(require 'ob-comint)
(require 'ob-eval)
(require 's)

;; possibly require modes required for your language
(define-derived-mode xslt-mode nxml-mode "xslt"
  "Major mode for editing xslt templates.")

(defcustom ob-xslt-oxygen-project-path "~/Projects/github.wdf.sap.corp/I074455/ems-cpi-xslt"
  "Oxygen XML project path which will be used in debug."
  :group 'org-babel
  :version "24.3"
  :type 'string)

(defcustom ob-xslt-command "saxon"
  "Name of xslt engine"
  :group 'org-babel
  :version "24.3"
  :type 'string)

(defcustom ob-xslt-debug-oxygen-param-template
  "<transformationParameter>
     <field name=\"paramDescription\">
        <paramDescriptor>
          <field name=\"localName\">
            <String>${field_name}</String>
          </field>
          <field name=\"prefix\"><null/></field>
          <field name=\"namespace\"><null/></field>
        </paramDescriptor>
    </field>
    <field name=\"value\">
       <String>${field_value}</String>
    </field>
    <field name=\"hasXPathValue\">
       <Boolean>false</Boolean>
    </field>
    <field name=\"isStatic\">
       <Boolean>false</Boolean>
    </field>
   </transformationParameter>"
  "Template for oxygen parameter.")

(defcustom ob-xslt-debug-oxygen-project-template
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<project>
  <meta>
    <filters directoryPatterns=\"\" filePatterns=\"\QOxygen.xpr\E\" positiveFilePatterns=\"\" showHiddenFiles=\"false\"/>
    <options>
      <serialized xml:space=\"preserve\">
                <serializableOrderedMap>
                    <entry>
                        <String>enable.project.master.files.support</String>
                        <Boolean>true</Boolean>
                    </entry>
                    <entry>
                        <String>scenario.associations</String>
                        <scenarioAssociation-array>
                            <scenarioAssociation>
                                <field name=\"url\">
                                    <String>${xslt-file-name}.xsl</String>
                                </field>
                                <field name=\"scenarioIds\">
                                    <list>
                                        <String>${xslt-file-name}</String>
                                    </list>
                                </field>
                                <field name=\"scenarioTypes\">
                                    <list>
                                        <String>XSL</String>
                                    </list>
                                </field>
                                <field name=\"scenarioStorageLocations\">
                                    <list>
                                        <Byte>2</Byte>
                                    </list>
                                </field>
                            </scenarioAssociation>
                        </scenarioAssociation-array>
                    </entry>
                    <entry>
                        <String>scenarios</String>
                        <scenario-array>
                            <scenario>
                                <field name=\"advancedOptionsMap\">
                                    <null/>
                                </field>
                                <field name=\"name\">
                                    <String>${xslt-file-name}</String>
                                </field>
                                <field name=\"baseURL\">
                                    <String/>
                                </field>
                                <field name=\"footerURL\">
                                    <String/>
                                </field>
                                <field name=\"fOPMethod\">
                                    <String>pdf</String>
                                </field>
                                <field name=\"fOProcessorName\">
                                    <String>Apache FOP</String>
                                </field>
                                <field name=\"headerURL\">
                                    <String/>
                                </field>
                                <field name=\"inputXSLURL\">
                                    <String>${xslt-file-path}</String>
                                </field>
                                <field name=\"inputXMLURL\">
                                    <String>${xml-file-path}</String>
                                </field>
                                <field name=\"defaultScenario\">
                                    <Boolean>false</Boolean>
                                </field>
                                <field name=\"isFOPPerforming\">
                                    <Boolean>false</Boolean>
                                </field>
                                <field name=\"type\">
                                    <String>XSL</String>
                                </field>
                                <field name=\"saveAs\">
                                    <Boolean>true</Boolean>
                                </field>
                                <field name=\"openInBrowser\">
                                    <Boolean>false</Boolean>
                                </field>
                                <field name=\"outputResource\">
                                    <null/>
                                </field>
                                <field name=\"openOtherLocationInBrowser\">
                                    <Boolean>false</Boolean>
                                </field>
                                <field name=\"locationToOpenInBrowserURL\">
                                    <null/>
                                </field>
                                <field name=\"openInEditor\">
                                    <Boolean>false</Boolean>
                                </field>
                                <field name=\"showInHTMLPane\">
                                    <Boolean>false</Boolean>
                                </field>
                                <field name=\"showInXMLPane\">
                                    <Boolean>true</Boolean>
                                </field>
                                <field name=\"showInSVGPane\">
                                    <Boolean>false</Boolean>
                                </field>
                                <field name=\"showInResultSetPane\">
                                    <Boolean>false</Boolean>
                                </field>
                                <field name=\"useXSLTInput\">
                                    <Boolean>true</Boolean>
                                </field>
                                <field name=\"xsltParams\">
                                    <list>
                                        ${param-str}
                                    </list>
                                </field>
                                <field name=\"cascadingStylesheets\">
                                    <String-array/>
                                </field>
                                <field name=\"xslTransformer\">
                                    <String>Saxon-EE</String>
                                </field>
                                <field name=\"extensionURLs\">
                                    <String-array>
                                        <String>${oxygen-extension-path}</String>
                                    </String-array>
                                </field>
                            </scenario>
                        </scenario-array>
                    </entry>
                </serializableOrderedMap>
            </serialized>
    </options>
  </meta>
  <projectTree name=\"Oxygen.xpr\">
    <folder masterFiles=\"true\" name=\"Main Files\">
      <file name=\"${xslt-file-name}.xsl\"/>
    </folder>
    <folder path=\"${oxygen-project-path}\"/>
  </projectTree>
</project>"
  "Oxygen project template used for debugging in Oxygen XML Developer.")

(defcustom ob-xslt-debug-oxygen-extension-path (expand-file-name
                                                (concat doom-private-dir "bin/SaxonExtension.jar"))
  "Oxygen XML developer - Extension path.")

;; optionally define a file extension for this language
(add-to-list 'org-babel-tangle-lang-exts '("xslt" . "xslt"))

(defun org-babel-execute:xslt (body params)
  "Execute a block of xslt code with org-babel.
This function is called by `org-babel-execute-src-block'"
  (let*
      ((processed-params (org-babel-process-params params))
       (tangle-file (cdr (assq :tangle processed-params)))
       (debug-enabled (cdr (assq :debug processed-params))))
    (ob-xslt-eval body params tangle-file debug-enabled)))

(defun ob-xslt-eval (body params tangle-file debug-enabled)
  "Run CMD on BODY.
If CMD succeeds then return its results, otherwise display
STDERR with `org-babel-eval-error-notify'."
  (let* ((vars (org-babel--get-vars params))
         (xml (s-replace-regexp "^#\+.*\n"
                                ""
                                (cdr (assq 'input vars)))))
    (if debug-enabled
        (let ((oxygen-xml-file (expand-file-name (concat ob-xslt-oxygen-project-path
                                                         "/testdata.xml")))
              (oxygen-project-file (expand-file-name (concat ob-xslt-oxygen-project-path
                                                             "/debug.xpr"))))
          (with-temp-file oxygen-xml-file
            (insert xml))
          (with-temp-file oxygen-project-file
            (insert
             (s-format ob-xslt-debug-oxygen-project-template 'aget
                       (list (cons "xslt-file-name" (file-name-base tangle-file))
                             (cons "xslt-file-path" (expand-file-name tangle-file))
                             (cons "xml-file-path" oxygen-xml-file)
                             (cons "oxygen-extension-path" ob-xslt-debug-oxygen-extension-path)
                             (cons "oxygen-project-path" (expand-file-name ob-xslt-oxygen-project-path))
                             (cons "param-str"
                                   (mapconcat
                                    (lambda (param)
                                      (when (and (equal (car param) :var)
                                                 (not (equal (car (cdr param) ) 'input)))
                                        (s-format ob-xslt-debug-oxygen-param-template
                                                  'aget
                                                  (list (cons "field_name" (symbol-name (car (cdr param))))
                                                        (cons "field_value" (cdr (cdr param)))))))
                                    (org-babel-process-params params) ""))))))
          (++async-shell-command
           (format "open %s" (shell-quote-argument oxygen-project-file))))
      (let ((xml-file (org-babel-temp-file "ob-xslt-xml-"))
            (xsl-file (org-babel-temp-file "ob-xslt-xsl-"))
            (param-items '())
            exit-code)
        (mapcar (lambda (var)
                  (when (not (eq (car var) 'input))
                    (add-to-list 'param-items (format "%s=%s" (car var) (cdr var)) t)))
                vars)
        (with-temp-file xsl-file (insert body))
        (with-temp-file xml-file (insert xml))
        (add-to-list 'param-items xml-file t)
        (add-to-list 'param-items xsl-file t)
        ;; (with-current-buffer err-buff (erase-buffer))
        ;; (setq exit-code
        ;;       (shell-command (format "%s %s %s %s"  ob-xslt-command param-str xml-file xsl-file) output-file err-buff))
        (with-temp-buffer
          (setq exit-code (apply #'call-process ob-xslt-command nil t nil (remq "" param-items)))
          (if (or (not (numberp exit-code)) (> exit-code 0))
              (progn
                (org-babel-eval-error-notify exit-code (buffer-string))
                (save-excursion
                  (when (get-buffer org-babel-error-buffer-name)
                    (with-current-buffer org-babel-error-buffer-name
                      (unless (derived-mode-p 'compilation-mode)
                        (compilation-mode))
                      ;; Compilation-mode enforces read-only, but Babel expects the buffer modifiable.
                      (setq buffer-read-only nil))))
                nil)
            (buffer-string)))))))

;; This function should be used to assign any variables in params in
;; the context of the session environment.
(defun org-babel-prep-session:xslt (session params)
  "Prepare SESSION according to the header arguments specified in PARAMS.")

;; (defun org-babel-xslt-var-to-xslt (var)
;;   "Convert an elisp var into a string of xslt source code
;; specifying a var of the same value."
;;   (format "%S" var))

;; (defun org-babel-xslt-table-or-string (results)
;;   "If the results look like a table, then convert them into an
;; Emacs-lisp table, otherwise return the results as a string.")

;; (defun org-babel-xslt-initiate-session (&optional session)
;;   "If there is not a current inferior-process-buffer in SESSION then create.
;; Return the initialized session."
;; (unless (string= session "none")))

(provide 'ob-xslt)
;;; ob-xslt.el ends here
