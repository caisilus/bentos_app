import React from "react";
import * as d3 from "d3";
import {Launch} from "./launch"

function LaunchList(props) {
    return (
        <aside className="aside" id="launchesContainer">
            <h3>Launches</h3>
            <div id="listContainer">
                <ul>
                    {props.launches.map((launch, i) => {
                        return <Launch key = {launch.id} launch = {launch}/>
                    })}
                </ul>
            </div>
        </aside>
    )
}

export {LaunchList}