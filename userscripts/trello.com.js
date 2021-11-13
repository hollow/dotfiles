// ==UserScript==
// @name         Trello Tweaks
// @namespace    https://github.com/hollow
// @version      0.3
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
    body {
        zoom: 80%;
    }

    .board-header-btns.mod-right .board-header-btn-text,
    .board-header-btns.mod-right .js-butler-header-btns {
        display: none;
    }

    .js-add-list {
        display: none;
    }

    .list-card-members {
        float: none;
    }

    span.custom-field-front-badges > span > div {
        display: block;
    }

    .badges .badge[title="Attachments"],
    .badges .badge[title="Checklist items"],
    .badges .badge[title="Comments"],
    .badges .badge[title="This card has a description."],
    .badges .badge[title="Trello attachments"],
    .badges .badge[title="You are subscribed to this card."],
    .badges .badge[title="You are watching this card."],
    .badges .js-plugin-badges > span > div {
        display: none;
    }
    </style>
    `).appendTo('head');
})(window.jQuery);
