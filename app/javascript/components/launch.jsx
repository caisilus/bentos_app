import React from "react";
import * as d3 from "d3";

function Launch(props) {
    const launch = props.launch

    const launchOnMouseOver = (event) => {
        const launchpadElement = d3.select(`#i${launch.launchpad}`)
        launchpadElement.attr("class", "highlightedLaunchpad")

        d3.select("#launchpads").selectAll("path").sort((a, b) => {
            if (a.id == launch.launchpad) {
                return 1
            }

            return -1
        })
    }

    const launchOnMouseLeave = (event) => {
        const launchpadElement = d3.select(`#i${launch.launchpad}`)
        launchpadElement.attr("class", "launchpad")
    }


    return (<li className="launchItem"
        onMouseOver={launchOnMouseOver}
        onMouseLeave={launchOnMouseLeave}>
        {launch.name}
    </li>)
}

export { Launch }