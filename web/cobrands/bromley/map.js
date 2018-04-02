fixmystreet.maps.tile_base = [ [ "", "a-" ], "https://{S}fix.bromley.gov.uk/tilma" ];

(function(){

if (!fixmystreet.maps) {
    return;
}

var defaults = {
    http_options: {
        url: "https://struan.tilma.dev.mysociety.org/mapserver/bromley_wfs",
        params: {
            SERVICE: "WFS",
            VERSION: "1.1.0",
            REQUEST: "GetFeature",
            SRSNAME: "urn:ogc:def:crs:EPSG::3857"
        }
    },
    format_class: OpenLayers.Format.GML.v3.MultiCurveFix,
    asset_type: 'spot',
    max_resolution: 2.388657133579254,
    min_resolution: 0.5971642833948135,
    asset_id_field: 'CENTRAL_AS',
    attributes: {
        central_asset_id: 'CENTRAL_AS',
        site_code: 'SITE_CODE'
    },
    geometryName: 'msGeometry',
    srsName: "EPSG:3857",
    strategy_class: OpenLayers.Strategy.FixMyStreet
};

fixmystreet.assets.add($.extend(true, {}, defaults, {
    http_options: {
        params: {
            TYPENAME: "Streetlights"
        }
    },
    asset_category: ["Faulty street light"],
    asset_item: 'street light'
}));

fixmystreet.assets.add($.extend(true, {}, defaults, {
    http_options: {
        params: {
            TYPENAME: "Litter_Bins"
        }
    },
    asset_category: ["Overflowing litter bin"],
    asset_item: 'litter bin'
}));

var highways_stylemap = new OpenLayers.StyleMap({
    'default': new OpenLayers.Style({
        fill: false,
        fillOpacity: 0,
        strokeColor: "#FF0000",
        strokeOpacity: 0.5,
        strokeWidth: 8
    })
});

fixmystreet.assets.add($.extend(true, {}, defaults, {
    http_options: {
        params: {
            TYPENAME: "TFL_Red_Route"
        }
    },
    stylemap: highways_stylemap,
    always_visible: true,
    non_interactive: true,
}));

})();
