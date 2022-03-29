using Plots
using CSV
using DataFrames
using DataFramesMeta
using StatsPlots
using HypothesisTests

gr()
default()
default(
    framestyle      =:axis,
    grid            =:y,
    axis            =:x,
    tick_direction  = :out,
    foreground_color_border = "#aaa",
    foreground_color_axis = "#aaa",
    msw=0.0,
    lw=2.0,
    fontfamily      ="Helvetica",
    guidefontsize   = 9,
    titlefontsize   = 10,
)

data = CSV.read("/path/to/csv/file/size_test.csv",DataFrame)
data = @where(data, :replicate .≤ 6)

data.radius = sqrt.(data.area / π)
data.diameter = data.radius * 2
data.diameter0 = zeros(size(data.diameter))

## Fold change diameter
for i = 1:nrow(data)
    hours,condition,replicate  = data[i,[:hours,:condition,:replicate]]
    data[i,:diameter0] = @where(data,:hours .== 0, :condition .== condition, :replicate .== replicate).diameter[1]
end
data.foldchange_pc = (data.diameter ./ data.diameter0 .- 1.0) * 100


## Plot initial diameters
data.diameter = 2 * data.radius
data_0 = @where(data,:hours .== 0)
figa = @df data_0 density(:diameter,fillrange=0.0,fα=0.2,legend=:none,xlabel="Diameter in PBS (µm)",yticks=[])

## Plot fold change vs time
figb = plot()
for (i,cond) in enumerate(unique(data.condition)), (j,rep) in enumerate(unique(data.replicate))
    data_i = sort(@where(data, :condition .== cond, :replicate .== rep),:hours)
    data_i.radius ./= data_i.radius[1]
    data_i.radius .-= 1.0
    data_i.radius .*= 100
    @df data_i plot!(figb,:hours, :radius,shape=:circle)
end
plot(figb,legend=:none,ylim=(-50,50),xlabel="Time (h)",lw=2.0,shape=:circle,xticks=0:24:168,ylabel="Diameter fold-change (%)")

## Fold change at 24, 48 and 72 hours
fc_12 = @where(data,:hours .== 12.0).foldchange_pc
fc_24 = @where(data,:hours .== 24.0).foldchange_pc
fc_72 = @where(data,:hours .== 72.0).foldchange_pc
fc_168 = @where(data,:hours .== 168.0).foldchange_pc

figc = density(fc_12,label="")
figc = density!(figc,fc_12,fillrange=0.0,fα=0.2,label="12 h")
figc = density!(figc,fc_24,fillrange=0.0,fα=0.2,label="24 h")
figc = density!(figc,fc_72,fillrange=0.0,fα=0.2,label="72 h")
figc = plot!(figc,xlim=(-11,11),xlabel="% diameter change",yticks=[])

plot(figa,figb,figc,layout=grid(1,3),size=(800,200))

savefig("fig.svg")