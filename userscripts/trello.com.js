// ==UserScript==
// @name         Trello Tweaks
// @namespace    https://github.com/hollow
// @version      0.2
// @description  Hide card badges, button texts and other display enhancements.
// @author       Benedikt Böhm
// @match        https://trello.com/b/*
// @icon         https://www.google.com/s2/favicons?domain=trello.com
// @grant        none
// ==/UserScript==

(function ($) {
    'use strict';

    $(`
    <style>
    .board-header-btns.mod-right .board-header-btn-text {
        display: none;
    }

    .js-add-list {
        display: none;
    }

    span.custom-field-front-badges > span > div {
        display: block;
    }
    </style>
    `).appendTo('head');

    setInterval(function () {
        $('.badges .badge[title="Attachments"]').parent().remove();
        $('.badges .badge[title="Checklist items"]').parent().remove();
        $('.badges .badge[title="Comments"]').parent().remove();
        $('.badges .badge[title="This card has a description."]').parent().remove();
        $('.badges .badge[title="Trello attachments"]').parent().remove();
        $('.badges .badge[title="You are subscribed to this card."]').parent().remove();
        $('.badges .badge[title="You are watching this card."]').parent().remove();
        // $('.badges .badge span[style*="github"]').parent().css("display", "none");
        $('.badges .badge span[style*="confluence.trello.services"]').parent().css("display", "none");
    }, 500);
})(window.jQuery);
