/*global require,exports,SyntaxHighlighter:true*/
/**
 * SyntaxHighlighter
 * http://alexgorbatchev.com/SyntaxHighlighter
 *
 * Brush for http://github.com/andreineculau/apiary.syntax.js
 * (and http://apiary.io)
 */
(function() {
    "use strict";

    // CommonJS
    SyntaxHighlighter =
        SyntaxHighlighter ||
        (typeof require !== 'undefined'? require('shCore').SyntaxHighlighter : null);

    function Brush()
    {
        var methods = 'CONNECT DELETE GET HEAD OPTIONS PATCH POST PUT TRACE';

        this.regexList = [
            {
                note: 'method',
                regex: new RegExp(this.getKeywords(methods), 'g'),
                css: 'color2'},
            {
                note: 'status',
                regex: /(<|&lt;) [1-9][0-9]{2,2}/g,
                css: 'color2'},
            {
                regex: /\:/g,
                css: 'color1'},
            {
                note: 'header key',
                regex: / [\w\-]+(?=:)/g,
                css: 'constants'},
            {
                note: 'in/out markers',
                regex: /^\s*<|&lt;|>|&gt;/g,
                css: 'keyword'}
        ];
    }

    Brush.prototype = new SyntaxHighlighter.Highlighter();
    Brush.aliases   = ['apiary'];

    SyntaxHighlighter.brushes.Apiary = Brush;

    // CommonJS
    if (typeof exports !== 'undefined') {
        exports.Brush = Brush;
    }
})();
