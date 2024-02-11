import React from "react";
import * as d3 from "d3";
import * as Geo from "../geo.json";
import {useRef, useEffect} from "react";

function launchpadToGeojson(launchpad) {
    return { "type": "Feature", 
             "geometry": {"type": "Point", "coordinates": [launchpad.longitude, launchpad.latitude]},
             "properties": {"name": launchpad.name},
             "id": launchpad.id
           }
}

function Map(props){
    const width = 1000;
    const height = 600;
    const margin = {
        top: 20,
        right: 20,
        bottom: 20,
        left: 100
    };
    const containerRef = useRef(null);

    useEffect(()=> { 
        let svg = d3.select(containerRef.current).select("svg")
        if (svg.empty()) {
            svg = d3.select(containerRef.current).append("svg")
        }
        svg.selectAll("*").remove();
        svg.attr("width", width + margin.left + margin.right)
            .attr("height", height + margin.top + margin.bottom )
            .append("g")
            .attr("transform", `translate(${margin.left},${margin.top})`)

        const projection = d3.geoMercator()
            .scale(70)
            .center([0, 20])
            .translate([width/2 - margin.left, height/2 - margin.top]);
        const g = svg.append("g");

        const path = d3.geoPath().projection(projection)

        g.selectAll("path")
            .data(Geo.features)
            .enter()
            .append("path")
            .attr("class", "topo")
            .attr("d", path)
            .style("opacity", .7)

        const launchpadsGeoData = props.launchpads.map(launchpadToGeojson)

        g.append("g")
            .attr("id", "launchpads")
            .selectAll("path")
            .data(launchpadsGeoData) 
            .enter()
            .append("path")
            .attr("d", path) 
            .attr("id", (d) => { return `i${d.id}` })
            .attr("class", "launchpad")
        
        const zoom = d3.zoom()
            .scaleExtent([1, 8])
            .on('zoom', function(event) {
                g.selectAll('path')
                    .attr('transform', event.transform);
            });

        svg.call(zoom); }, [props.launchpads]);

    return(
        <div className="mapContainer map" ref={containerRef}>
        </div>
    )
}

export {Map}